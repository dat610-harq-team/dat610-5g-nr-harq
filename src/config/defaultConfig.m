function cfg = defaultConfig()
%DEFAULTCONFIG Shared baseline settings for the integrated HARQ simulator.
%
% Person 1 owns the shared experiment entry point. Person 2's HARQ/event
% implementation is now used underneath runSimulation.
%
% Values are starting points and still need final scientific justification.

    cfg.NumTransportBlocks = 300;
    cfg.Seed = 610;

    % HARQ
    cfg.NHARQProcesses = 16;
    cfg.RVSequence = [0 2 3 1];

    % Carrier / PDSCH
    cfg.TargetCodeRate = 490/1024;
    cfg.SubcarrierSpacing = 15;    % kHz
    cfg.NSizeGrid = 12;            % Compact allocation used by Person 2
    cfg.CyclicPrefix = "Normal";
    cfg.Modulation = "16QAM";
    cfg.NumLayers = 1;

    % Decoder
    cfg.LDPCDecodingAlgorithm = "Normalized min-sum";
    cfg.MaximumLDPCIterationCount = 6;

    % Shared experiment policy
    % Keep channel-specific settings out of this baseline until Person 3's
    % waveform channel path is integrated.
end
