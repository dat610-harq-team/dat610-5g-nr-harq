function cfg = defaultConfig()
%DEFAULTCONFIG Baseline settings for the first working HARQ simulation.
% Owner: Person 1; scientific values must still be reviewed by the group.
%
% These baseline values come from the R2022a MathWorks example
% "Model 5G NR Transport Channels with HARQ". They are a starting point,
% not final experimental choices.

    cfg.NumTransportBlocks = 20;   % Small value for fast smoke tests
    cfg.RandomSeed = "default";

    % DL-SCH / HARQ baseline
    cfg.TargetCodeRate = 490/1024;
    cfg.RVSequence = [0 2 3 1];
    % Fixed cyclic scheduler: one process scheduled per slot, ideal feedback.
    % Set to 1 for sequential HARQ; supported range is 1 to 16 processes.
    cfg.NHARQProcesses = 16;

    % Carrier baseline
    cfg.SubcarrierSpacing = 15;    % kHz
    cfg.NSizeGrid = 52;            % 52 RBs ~= 10 MHz at 15 kHz SCS
    cfg.CyclicPrefix = "Normal";

    % PDSCH baseline
    cfg.Modulation = "16QAM";
    cfg.NumLayers = 1;

    % Decoder baseline
    cfg.LDPCDecodingAlgorithm = "Normalized min-sum";
    cfg.MaximumLDPCIterationCount = 6;

    % Before final report:
    % - choose run length using pilot results and confidence intervals
    % - refine SNR points around the observed BLER transition
    % - review the experiment's 16-process cyclic HARQ scheduler
    % - document parameter sources and justify experiment-specific choices
end
