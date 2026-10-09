function tests = testHarqExperiment
% Meaningful metric histories plus integration with actual R2026a NR coding.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root,'experiments'));
    setupHarqExperiment();
    testCase.TestData.cfg = harqExperimentConfig('quick');
end

function testSharedBaseline(testCase)
    baseline = defaultConfig();
    cfg = harqExperimentConfig('quick');
    fields = fieldnames(baseline);
    for k = 1:numel(fields)
        verifyEqual(testCase,cfg.(fields{k}),baseline.(fields{k}));
    end
    verifyEqual(testCase,cfg.RVSequences{end},baseline.RVSequence(:).');
    if isequal(string(baseline.RandomSeed),"default")
        verifyEqual(testCase,cfg.Seeds,0);
    else
        verifyEqual(testCase,cfg.Seeds,baseline.RandomSeed);
    end
end

function testKnownMetricsAndCensoring(testCase)
    % TB1 succeeds immediately; TB2 succeeds after retry; TB3 drops; TB4 pending.
    raw.events = table([1;2;2;3;3;4],[0;1;3;2;4;5],[1;1;2;1;2;1], ...
        100*ones(6,1),logical([0;1;0;1;1;1]),logical([1;0;1;0;1;0]), ...
        'VariableNames',{'tbId','slot','attempt','tbsBits','crcError','terminal'});
    raw.numSlots = 8; raw.slotDurationSeconds = 0.001;
    m = calculateMetrics(raw);
    verifyEqual(testCase,m.firstTransmissionBLER,3/4);
    verifyEqual(testCase,m.finalResidualBLER,1/3,'AbsTol',1e-12);
    verifyEqual(testCase,m.goodputBitsPerSecond,25000);
    verifyEqual(testCase,m.meanRetransmissionsPerDeliveredTb,0.5);
    verifyEqual(testCase,m.retransmissionProbability,2/3,'AbsTol',1e-12);
    verifyEqual(testCase,m.meanDeliveryLatencySlots,2);
    verifyEqual(testCase,m.incompleteTransportBlocks,1);
    verifyEqual(testCase,m.idleSlots,2);
    raw.events.terminal(1) = false;
    verifyError(testCase,@()calculateMetrics(raw),'calculateMetrics:NonterminalSuccess');
end

function testAllFailuresGiveUndefinedConditionalMeans(testCase)
    raw.events = table(1,0,1,100,true,true,'VariableNames', ...
        {'tbId','slot','attempt','tbsBits','crcError','terminal'});
    raw.numSlots = 1; raw.slotDurationSeconds = 0.001;
    m = calculateMetrics(raw);
    verifyEqual(testCase,m.finalResidualBLER,1);
    verifyEqual(testCase,m.goodputBitsPerSecond,0);
    verifyTrue(testCase,isnan(m.meanDeliveryLatencySlots));
    verifyTrue(testCase,isnan(m.meanRetransmissionsPerDeliveredTb));
end

function testOfficialHelperRVAndTimeout(testCase)
    for sequence = {0,[0 2],[0 2 3 1],[0 0 0 0]}
        rv = sequence{1};
        h = HARQEntity(0,rv,1);
        for k = 1:numel(rv)
            verifyEqual(testCase,h.TransmissionNumber,k-1);
            verifyEqual(testCase,h.RedundancyVersion,rv(k));
            verifyEqual(testCase,h.NewData,k==1);
            updateAndAdvance(h,true,100,300);
        end
        verifyTrue(testCase,logical(h.NewData));
        verifyTrue(testCase,logical(h.SequenceTimeout));
        updateAndAdvance(h,false,100,300);
        verifyTrue(testCase,logical(h.NewData));
        verifyFalse(testCase,logical(h.SequenceTimeout));
    end
end

function testHighSNRAndRepeatability(testCase)
    cfg = testCase.TestData.cfg;
    cfg.NumTransportBlocks = 4; cfg.NHARQProcesses = 2;
    scenario = struct('SNRdB',40,'Seed',7,'RVSequence',[0 2 3 1]);
    a = runHarqLinkSimulation(cfg,scenario);
    b = runHarqLinkSimulation(cfg,scenario);
    verifyEqual(testCase,a.raw,b.raw);
    verifyEqual(testCase,a.metrics.deliveredTransportBlocks,4);
    verifyEqual(testCase,a.metrics.retransmissionAttempts,0);
    verifyEqual(testCase,a.metrics.meanDeliveryLatencySlots,1);
end

function testRetryLimitBufferResetAndDrain(testCase)
    cfg = testCase.TestData.cfg;
    cfg.NumTransportBlocks = 3; cfg.NHARQProcesses = 2;
    scenario = struct('SNRdB',-40,'Seed',8,'RVSequence',[0 2]);
    r = runHarqLinkSimulation(cfg,scenario);
    verifyEqual(testCase,r.metrics.droppedTransportBlocks,3);
    verifyEqual(testCase,r.metrics.transmissionAttempts,6);
    verifyEqual(testCase,r.metrics.incompleteTransportBlocks,0);
    verifyEqual(testCase,r.raw.numSlots,7); % Idle slot while final TB waits
    e = r.raw.events;
    verifyEqual(testCase,e.rv(e.attempt==2),2*ones(3,1));
    verifyTrue(testCase,e.softBufferReset(e.tbId==3 & e.attempt==1));
    scenario.RVSequence = 0;
    off = runHarqLinkSimulation(cfg,scenario);
    verifyEqual(testCase,off.metrics.transmissionAttempts,3);
    verifyEqual(testCase,off.metrics.retransmissionProbability,0);
    verifyTrue(testCase,off.raw.events.softBufferReset(3));
end

function testCombiningAndMatchedInitialAttempts(testCase)
    cfg = testCase.TestData.cfg;
    cfg.NumTransportBlocks = 16; cfg.NHARQProcesses = 4;
    scenario = struct('SNRdB',6,'Seed',9,'RVSequence',0);
    off = runHarqLinkSimulation(cfg,scenario);
    scenario.RVSequence = [0 2 3 1];
    ir = runHarqLinkSimulation(cfg,scenario);
    verifyEqual(testCase,ir.raw.events.crcError(ir.raw.events.attempt==1),off.raw.events.crcError);
    verifyLessThan(testCase,ir.metrics.finalResidualBLER,ir.metrics.firstTransmissionBLER);
    delivered = ir.raw.events(~ir.raw.events.crcError,:);
    verifyEqual(testCase,delivered.slot-delivered.firstSlot+1, ...
        1+(delivered.attempt-1)*cfg.NHARQProcesses);
    scenario.RVSequence = [0 0 0 0];
    repeated = runHarqLinkSimulation(cfg,scenario);
    verifyEqual(testCase,repeated.raw.events.rv,zeros(height(repeated.raw.events),1));
    verifyLessThan(testCase,repeated.metrics.finalResidualBLER,repeated.metrics.firstTransmissionBLER);
end

function testPooledSummary(testCase)
    r = table(["test";"test"],[0;0],[2;2],[0;2],[2;0],[2;1], ...
        [NaN;0.5],[NaN;9],[0;200],[0.004;0.002],[0;1],[0;1],[2;3], ...
        'VariableNames',{'configuration','snrDb','observedTransportBlocks', ...
        'deliveredTransportBlocks','droppedTransportBlocks','firstTransmissionErrors', ...
        'meanRetransmissionsPerDeliveredTb','meanDeliveryLatencySlots', ...
        'deliveredTransportBlockBits','elapsedSeconds','retransmittedTransportBlocks', ...
        'retransmissionAttempts','transmissionAttempts'});
    s = summarizeHarqRuns(r);
    verifyEqual(testCase,s.finalResidualBLER,0.5);
    verifyEqual(testCase,s.meanRetransmissionsPerDeliveredTb,0.5);
    verifyEqual(testCase,s.meanDeliveryLatencySlots,9);
    verifyEqual(testCase,s.goodputMbps,200/0.006/1e6,'AbsTol',1e-12);
    verifyLessThan(testCase,s.finalBLERLow95,0.5);
    verifyGreaterThan(testCase,s.finalBLERHigh95,0.5);
end
