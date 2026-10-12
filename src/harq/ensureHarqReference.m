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

    matlabUserPath = userpath;
    if contains(matlabUserPath,pathsep)
        matlabUserPath = extractBefore(matlabUserPath,pathsep);
    end

    releaseName = version("-release");

    % First try the two known MathWorks example folder names for the
    % currently running MATLAB release.
    candidates = {
        fullfile(matlabUserPath,"Examples",releaseName,"5g", ...
            "Modeling5GNRTransportChannelsWithHARQExample")
        fullfile(matlabUserPath,"Examples",releaseName,"5g", ...
            "Model5GNRTransportChannelsWithHARQExample")
    };

    for idx = 1:numel(candidates)
        helper = fullfile(candidates{idx},"HARQEntity.m");
        if isfile(helper)
            addpath(candidates{idx},"-begin");
            helperPath = which("HARQEntity");
            return;
        end
    end

    % If MATLAB was upgraded, the example may still exist under a different
    % release folder (for example R2022a). Search installed example folders.
    searchPattern = fullfile(matlabUserPath,"Examples","R*","5g","*HARQ*","HARQEntity.m");
    matches = dir(searchPattern);

    if ~isempty(matches)
        helperFolder = matches(1).folder;
        addpath(helperFolder,"-begin");
        helperPath = which("HARQEntity");
        fprintf("Using HARQEntity from: %s\n",helperPath);
        return;
    end

    error('HARQ:MissingReferenceHelper', ...
        ['HARQEntity.m was not found. Open the MathWorks example ' ...
         '''Model 5G NR Transport Channels with HARQ'' once, then rerun.']);
end
