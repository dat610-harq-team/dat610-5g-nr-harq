function helperPath = ensureHarqReference()
%ENSUREHARQREFERENCE Make the MathWorks HARQEntity helper available.
%
% Person 2's simulator intentionally reuses MathWorks' HARQEntity helper
% instead of duplicating the HARQ process state machine.

    existing = which("HARQEntity");
    if ~isempty(existing)
        helperPath = existing;
        return;
    end

    % MathWorks examples are commonly stored below the MATLAB user folder.
    matlabUserPath = userpath;
    if contains(matlabUserPath,pathsep)
        matlabUserPath = extractBefore(matlabUserPath,pathsep);
    end

    releaseName = version("-release");

    candidates = {
        fullfile(matlabUserPath,"Examples",releaseName,"5g", ...
            "Modeling5GNRTransportChannelsWithHARQExample")
        fullfile(matlabUserPath,"Examples",releaseName,"5g", ...
            "Model5GNRTransportChannelsWithHARQExample")
    };

    for idx = 1:numel(candidates)
        candidate = candidates{idx};
        helper = fullfile(candidate,"HARQEntity.m");
        if isfile(helper)
            addpath(candidate,"-begin");
            helperPath = which("HARQEntity");
            return;
        end
    end

    error("HARQ:MissingReferenceHelper", ...
        ["HARQEntity.m was not found. Open the MathWorks example " ...
         "'Model 5G NR Transport Channels with HARQ' once, then rerun."]);
end
