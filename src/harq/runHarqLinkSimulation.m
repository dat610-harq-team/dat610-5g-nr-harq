function result = runHarqLinkSimulation(cfg, scenario)
%RUNHARQLINKSIMULATION Instrument the official NR transport-channel HARQ flow.
% One layer/codeword, fixed TBS, symbol-domain AWGN, cyclic process schedule.
% scenario: SNRdB, Seed, RVSequence. The finite TB cohort is fully resolved.
% runSimulation.m remains the integration entry point for the team's waveform.
    validateattributes(cfg.NumTransportBlocks,{'numeric'},{'scalar','integer','positive','finite'});
    validateattributes(cfg.NHARQProcesses,{'numeric'},{'scalar','integer','>=',1,'<=',16});
    validateattributes(cfg.NSizeGrid,{'numeric'},{'scalar','integer','>=',1,'<=',275});
    validateattributes(cfg.TargetCodeRate,{'numeric'},{'scalar','>',0,'<',1});
    validateattributes(scenario.SNRdB,{'numeric'},{'scalar','real','finite'});
    validateattributes(scenario.Seed,{'numeric'},{'scalar','integer','nonnegative','<=',2^32-1});
    rvSequence = scenario.RVSequence(:).';
    validateattributes(rvSequence,{'numeric'},{'nonempty','integer','>=',0,'<=',3});
    assert(numel(rvSequence)<=4 && rvSequence(1)==0,'HARQ:RVSequence', ...
        'Use one to four attempts, starting with RV 0.');
    assert(cfg.NumLayers==1,'HARQ:NumLayers', ...
        'This symbol-domain experiment supports one layer/codeword.');
    assert(strcmpi(cfg.CyclicPrefix,'Normal'),'HARQ:CyclicPrefix', ...
        'This full-slot experiment supports normal cyclic prefix.');
    carrier = nrCarrierConfig;
    carrier.NSizeGrid = cfg.NSizeGrid;
    carrier.SubcarrierSpacing = cfg.SubcarrierSpacing;
    carrier.CyclicPrefix = cfg.CyclicPrefix;
    carrier.NCellID = 0;
    pdsch = nrPDSCHConfig;
    pdsch.Modulation = cfg.Modulation;
    pdsch.NumLayers = cfg.NumLayers;
    pdsch.PRBSet = 0:cfg.NSizeGrid-1;
    pdsch.SymbolAllocation = [0 14];
    pdsch.MappingType = 'A';
    pdsch.RNTI = 1;
    pdsch.NID = 0;
    pdsch.EnablePTRS = false;
    pdsch.DMRS.DMRSConfigurationType = 1;
    pdsch.DMRS.DMRSLength = 1;
    pdsch.DMRS.DMRSAdditionalPosition = 0;
    pdsch.DMRS.DMRSTypeAPosition = 2;
    pdsch.DMRS.NumCDMGroupsWithoutData = 2;
    [~,pdschInfo] = nrPDSCHIndices(carrier,pdsch);
    tbs = nrTBS(pdsch.Modulation,1,numel(pdsch.PRBSet), ...
        pdschInfo.NREPerPRB,cfg.TargetCodeRate,0);
    encoder = nrDLSCH('MultipleHARQProcesses',true, ...
        'TargetCodeRate',cfg.TargetCodeRate);
    decoder = nrDLSCHDecoder('MultipleHARQProcesses',true, ...
        'TargetCodeRate',cfg.TargetCodeRate,'TransportBlockLength',tbs, ...
        'LDPCDecodingAlgorithm',cfg.LDPCDecodingAlgorithm, ...
        'MaximumLDPCIterationCount',cfg.MaximumLDPCIterationCount, ...
        'AutoFlushSoftBuffer',true);
    harq = HARQEntity(0:cfg.NHARQProcesses-1,rvSequence,1);
    % Independent substreams per TB/attempt match initial random draws across
    % budgets even when the number of retransmissions changes.
    payloadStream = RandStream('mrg32k3a','Seed',scenario.Seed);
    noiseStream = RandStream('mrg32k3a','Seed',mod(scenario.Seed+100000,2^32));
    noiseVariance = 10^(-scenario.SNRdB/10); % E[abs(complex noise)^2]
    maxEvents = cfg.NumTransportBlocks*numel(rvSequence);
    names = {'tbId','harqProcessId','codewordId','slot','attempt','rv', ...
        'tbsBits','crcError','terminal','firstSlot','softBufferReset'};
    types = [repmat({'double'},1,7),{'logical','logical','double','logical'}];
    events = table('Size',[maxEvents,numel(names)],'VariableTypes',types,'VariableNames',names);
    active = false(cfg.NHARQProcesses,1);
    admitted = 0;
    slot = 0;
    nEvents = 0;
    % After admission closes, unused processes idle. Count these slots to
    % preserve retransmission spacing and the elapsed-time denominator.
    while admitted < cfg.NumTransportBlocks || any(active)
        pid = harq.HARQProcessID;
        if harq.NewData && admitted == cfg.NumTransportBlocks
            advanceToNextProcess(harq);
            slot = slot+1;
            continue;
        end
        carrier.NSlot = slot;
        didReset = false;
        if harq.NewData
            admitted = admitted+1;
            payloadStream.Substream = admitted;
            tb = randi(payloadStream,[0 1],tbs,1,'int8');
            setTransportBlock(encoder,tb,0,pid);
            if harq.SequenceTimeout
                resetSoftBuffer(decoder,0,pid);
                didReset = true;
            end
            harq.UserData = struct('tbId',admitted,'firstSlot',slot);
            active(pid+1) = true;
        end
        tbInfo = harq.UserData;
        attempt = harq.TransmissionNumber+1; % Helper is zero-based
        rv = harq.RedundancyVersion;
        coded = encoder(pdsch.Modulation,1,pdschInfo.G,rv,pid);
        symbols = nrPDSCH(carrier,pdsch,coded);
        noiseStream.Substream = (tbInfo.tbId-1)*4+attempt;
        noise = sqrt(noiseVariance/2)*(randn(noiseStream,size(symbols)) + ...
            1i*randn(noiseStream,size(symbols)));
        llrs = nrPDSCHDecode(carrier,pdsch,symbols+noise,noiseVariance);
        [~,crcError] = decoder(llrs,pdsch.Modulation,1,rv,pid);
        terminal = ~crcError || attempt == numel(rvSequence);
        nEvents = nEvents+1;
        events(nEvents,:) = {tbInfo.tbId,pid,0,slot,attempt,rv,tbs, ...
            logical(crcError),logical(terminal),tbInfo.firstSlot,didReset};
        if terminal, active(pid+1) = false; end
        % Capture identifiers above before selecting the next process.
        updateAndAdvance(harq,crcError,tbs,pdschInfo.G);
        slot = slot+1;
    end
    raw = struct('events',events(1:nEvents,:),'numSlots',slot, ...
        'slotDurationSeconds',1e-3*15/cfg.SubcarrierSpacing);
    result.cfg = cfg;
    result.scenario = scenario;
    result.raw = raw;
    result.metrics = calculateMetrics(raw);
    result.link = struct('tbsBits',tbs,'codedBitsPerAttempt',pdschInfo.G, ...
        'noiseVariance',noiseVariance,'snrDefinition','PDSCH symbol Es/N0 (dB)', ...
        'carrier',carrier,'pdsch',pdsch);
    assert(result.metrics.incompleteTransportBlocks==0,'HARQ:UnresolvedCohort', ...
        'The simulation must resolve every admitted TB.');
end
