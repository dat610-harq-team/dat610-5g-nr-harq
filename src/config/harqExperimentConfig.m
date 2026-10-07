function cfg = harqExperimentConfig(mode)
%HARQEXPERIMENTCONFIG Person 2's symbol-domain NR HARQ/AWGN experiment.
% Project settings, not properties of a MathWorks configuration object.
% quick is a runnable pilot, study needs statistical review before reporting.
    arguments
        mode (1,1) string {mustBeMember(mode,["quick","study"])} = "quick"
    end
    cfg.Mode = mode;
    cfg.SNRdB = [-4 0 7 10];         % Es/N0; includes low SNR and decoder transition
    cfg.Seeds = 610;
    cfg.NumTransportBlocks = 64;     % New TBs per SNR/seed/config; drain all
    cfg.NHARQProcesses = 16;         % Fixed cyclic scheduler, ideal feedback
    cfg.RVSequences = {0, [0 2], [0 2 3 1]};
    cfg.Labels = ["No retransmissions", "Max 1 retransmission", "Max 3 retransmissions"];
    cfg.NSizeGrid = 12;              % Small allocation for a tractable pilot
    cfg.SubcarrierSpacing = 15;      % kHz; normal CP, 1 ms slots
    cfg.Modulation = "16QAM";
    cfg.TargetCodeRate = 490/1024;
    cfg.MaximumLDPCIterationCount = 6;
    cfg.LDPCDecodingAlgorithm = "Normalized min-sum";
    cfg.ShowFigures = true;
    cfg.SaveResults = true;
    if mode == "study"
        cfg.SNRdB = [-4 -2 0 2 4 6 7 8 10];
        cfg.Seeds = [610 611 612];
        cfg.NumTransportBlocks = 1000;
    end
end
