function cfg = harqExperimentConfig(mode)
%HARQEXPERIMENTCONFIG Person 2's symbol-domain NR HARQ/AWGN experiment.
% Project settings, not properties of a MathWorks configuration object.
% quick is a runnable pilot, study needs statistical review before reporting.
    arguments
        mode (1,1) string {mustBeMember(mode,["quick","study"])} = "quick"
    end
    cfg = defaultConfig();
    cfg.Mode = mode;
    cfg.SNRdB = [-4 0 7 10];         % Es/N0; includes low SNR and decoder transition
    % Numeric seed for independent per-TB streams; do not reset global rng.
    if isequal(string(cfg.RandomSeed), "default")
        cfg.Seeds = 0;
    else
        validateattributes(cfg.RandomSeed,{'numeric'}, ...
            {'scalar','integer','nonnegative','<=',2^32-1});
        cfg.Seeds = cfg.RandomSeed;
    end
    rv = cfg.RVSequence;
    validateattributes(rv,{'numeric'},{'vector','nonempty','integer','>=',0,'<=',3});
    assert(numel(rv)<=4 && rv(1)==0,'HARQ:RVSequence', ...
        'Use one to four attempts, starting with RV 0.');
    budgets = unique([1 min(2,numel(rv)) numel(rv)],'stable');
    cfg.RVSequences = arrayfun(@(n) reshape(rv(1:n),1,[]),budgets,'UniformOutput',false);
    cfg.Labels = "Max " + string(budgets-1) + " retransmissions";
    cfg.Labels(budgets==1) = "No retransmissions";
    cfg.Labels(budgets==2) = "Max 1 retransmission";
    cfg.ShowFigures = true;
    cfg.SaveResults = true;
    if mode == "study"
        cfg.SNRdB = [-4 -2 0 2 4 6 7 8 10];
        cfg.Seeds = mod(double(cfg.Seeds)+(0:2),2^32);
        cfg.NumTransportBlocks = 1000;
    end
end
