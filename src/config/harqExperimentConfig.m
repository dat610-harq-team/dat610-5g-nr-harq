function cfg = harqExperimentConfig(mode)
%HARQEXPERIMENTCONFIG Person 2's symbol-domain NR HARQ/AWGN experiment.
% Project settings, not properties of a MathWorks configuration object.
% quick is a runnable pilot, study needs statistical review before reporting.
    arguments
        mode (1,1) string {mustBeMember(mode,["quick","study"])} = "quick"
    end

    % Inherit the same baseline used by the shared simulator so Person 1 and
    % Person 2 do not silently run different radio configurations.
    cfg = defaultConfig();
    cfg.Mode = mode;
    cfg.SNRdB = [-4 0 7 10];

    % Use the shared numeric seed as the first experiment seed.
    cfg.Seeds = cfg.Seed;

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
        cfg.Seeds = mod(double(cfg.Seed)+(0:2),2^32);
        cfg.NumTransportBlocks = 1000;
    end
end
