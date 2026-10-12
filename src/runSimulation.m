function result = runSimulation(cfg, scenario)
%RUNSIMULATION Shared entry point for one 5G NR HARQ scenario.
%
% This function now delegates the HARQ mechanics and event recording to
% Person 2's runHarqLinkSimulation implementation.
%
% Inputs:
%   cfg      - shared simulation configuration
%   scenario - experiment-specific settings; SNRdB is required
%
% Optional scenario fields:
%   Seed       - random seed; defaults to cfg.Seed
%   RVSequence - HARQ redundancy-version sequence; defaults to cfg.RVSequence
%
% Output:
%   result.raw.events - one row per transport-block transmission attempt
%   result.metrics    - metrics calculated from the raw event history
%
% The public project contract remains:
%   result = runSimulation(cfg, scenario)

    if ~isfield(scenario,"SNRdB")
        error("runSimulation:MissingSNR", ...
            "scenario.SNRdB must be provided.");
    end

    if ~isfield(scenario,"Seed")
        scenario.Seed = cfg.Seed;
    end

    if ~isfield(scenario,"RVSequence")
        scenario.RVSequence = cfg.RVSequence;
    end

    ensureHarqReference();

    result = runHarqLinkSimulation(cfg,scenario);
end
