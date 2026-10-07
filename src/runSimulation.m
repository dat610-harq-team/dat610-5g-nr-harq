function result = runSimulation(cfg, scenario)
%RUNSIMULATION Run one baseline 5G NR HARQ scenario.
% Owner: Person 1; integrate later with Person 2 (HARQ/metrics)
% and Person 3 (channel models).
%
% Inputs:
%   cfg      - shared baseline configuration from defaultConfig
%   scenario - experiment-specific settings; currently requires SNRdB
%
% Output:
%   result.raw - raw observations/counters only. Metric definitions remain
%                a group decision and belong in calculateMetrics.m.
%
% First implementation scope:
%   - one HARQ process
%   - DL-SCH + PDSCH
%   - AWGN channel
%   - sequential retransmissions using the configured RV sequence
%
% This is intentionally a simple working baseline, not the final simulator.

    if ~isfield(scenario,"SNRdB")
        error("runSimulation:MissingSNR", ...
            "scenario.SNRdB must be provided.");
    end

    rng(cfg.RandomSeed);

    % DL-SCH encoder/decoder. We use process ID 0 for the first baseline.
    encodeDLSCH = nrDLSCH;
    encodeDLSCH.MultipleHARQProcesses = true;
    encodeDLSCH.TargetCodeRate = cfg.TargetCodeRate;

    decodeDLSCH = nrDLSCHDecoder;
    decodeDLSCH.MultipleHARQProcesses = true;
    decodeDLSCH.TargetCodeRate = cfg.TargetCodeRate;
    decodeDLSCH.LDPCDecodingAlgorithm = cfg.LDPCDecodingAlgorithm;
    decodeDLSCH.MaximumLDPCIterationCount = cfg.MaximumLDPCIterationCount;

    % Carrier.
    carrier = nrCarrierConfig;
    carrier.NSizeGrid = cfg.NSizeGrid;
    carrier.SubcarrierSpacing = cfg.SubcarrierSpacing;
    carrier.CyclicPrefix = cfg.CyclicPrefix;

    % PDSCH.
    pdsch = nrPDSCHConfig;
    pdsch.Modulation = cfg.Modulation;
    pdsch.PRBSet = 0:cfg.NSizeGrid-1;
    pdsch.NumLayers = cfg.NumLayers;

    noiseVar = 1/(10^(scenario.SNRdB/10));

    nBlocks = cfg.NumTransportBlocks;
    attemptsPerBlock = zeros(1,nBlocks);
    firstAttemptBlockError = false(1,nBlocks);
    finalBlockError = false(1,nBlocks);
    transportBlockSizes = zeros(1,nBlocks);

    harqProcessID = 0;
    codewordIndex = 0;

    for nTrBlk = 1:nBlocks

        % Keep the first baseline close to the MathWorks example:
        % one new transport block per logical iteration.
        carrier.NSlot = carrier.NSlot + 1;

        [~,pdschInfo] = nrPDSCHIndices(carrier,pdsch);

        xOverhead = 0;
        trBlkSize = nrTBS( ...
            pdsch.Modulation, ...
            pdsch.NumLayers, ...
            numel(pdsch.PRBSet), ...
            pdschInfo.NREPerPRB, ...
            cfg.TargetCodeRate, ...
            xOverhead);

        transportBlockSizes(nTrBlk) = trBlkSize;

        % New information bits for this transport block.
        trBlk = randi([0 1],trBlkSize,1);
        setTransportBlock(encodeDLSCH,trBlk,codewordIndex,harqProcessID);

        delivered = false;

        for attempt = 1:numel(cfg.RVSequence)

            rv = cfg.RVSequence(attempt);

            codedTrBlock = encodeDLSCH( ...
                pdsch.Modulation, ...
                pdsch.NumLayers, ...
                pdschInfo.G, ...
                rv, ...
                harqProcessID);

            modOut = nrPDSCH(carrier,pdsch,codedTrBlock);

            % Baseline channel. Person 3 will later replace/isolate this
            % through the shared channel boundary.
            rxSig = awgn(modOut,scenario.SNRdB);

            rxLLR = nrPDSCHDecode(carrier,pdsch,rxSig,noiseVar);

            decodeDLSCH.TransportBlockLength = trBlkSize;
            [~,blkerr] = decodeDLSCH( ...
                rxLLR, ...
                pdsch.Modulation, ...
                pdsch.NumLayers, ...
                rv, ...
                harqProcessID);

            if attempt == 1
                firstAttemptBlockError(nTrBlk) = logical(blkerr);
            end

            if ~blkerr
                delivered = true;
                break;
            end
        end

        attemptsPerBlock(nTrBlk) = attempt;
        finalBlockError(nTrBlk) = ~delivered;

        % The decoder clears its soft buffer after successful reception.
        % If every RV failed, clear it before starting a new transport block.
        if ~delivered
            resetSoftBuffer(decodeDLSCH,codewordIndex,harqProcessID);
        end
    end

    % Raw observations. Person 2 can use these to define/verify metrics.
    result.scenario = scenario;

    result.raw.totalTransportBlocks = nBlocks;
    result.raw.transportBlockSizes = transportBlockSizes;
    result.raw.firstAttemptBlockError = firstAttemptBlockError;
    result.raw.finalBlockError = finalBlockError;
    result.raw.attemptsPerBlock = attemptsPerBlock;

    result.raw.totalTransmissionAttempts = sum(attemptsPerBlock);
    result.raw.totalRetransmissions = sum(attemptsPerBlock - 1);
    result.raw.finalFailedTransportBlocks = sum(finalBlockError);

    result.raw.attemptedInformationBits = sum(transportBlockSizes);
    result.raw.successfullyDeliveredBits = ...
        sum(transportBlockSizes(~finalBlockError));
end
