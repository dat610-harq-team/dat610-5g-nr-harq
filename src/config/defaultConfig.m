function cfg = defaultConfig()
%DEFAULTCONFIG Shared starting configuration for future simulations.
% Owner: Person 1; agree on scientific settings with the whole group.
% Output: cfg - a configuration struct for runSimulation.
%
% Values are provisional until justified through literature and the
% MATLAB reference example. The single flag below is an interface hint,
% not evidence that the reference supports a fair on/off comparison.

    cfg.EnableHARQ = true;

    % TODO: Decide simulation duration and SNR range.
    % TODO: Decide channel and NR/PDSCH configuration.
    % TODO: Record units and reasons for every chosen value.
end
