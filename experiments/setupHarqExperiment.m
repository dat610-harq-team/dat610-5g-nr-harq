function environment = setupHarqExperiment()
%SETUPHARQEXPERIMENT Check R2026a and obtain its official HARQ example helper.
% setupExample is MATLAB's example retrieval utility, not a 5G Toolbox API.
% Its implementation was inspected in R2026a. No GUI or add-on install needed.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(root,'src')));
    if ~strcmp(version('-release'),'2026a')
        error('HARQ:Release','This setup targets MATLAB R2026a. Current release: %s.',version('-release'));
    end
    required = {'nrDLSCH','nrDLSCHDecoder','nrCarrierConfig','nrPDSCHConfig', ...
        'nrPDSCHIndices','nrTBS','nrPDSCH','nrPDSCHDecode'};
    for k = 1:numel(required)
        if isempty(which(required{k}))
            error('HARQ:MissingToolbox','Missing %s. Install 5G Toolbox for R2026a.',required{k});
        end
    end
    exampleId = '5g/Modeling5GNRTransportChannelsWithHARQExample';
    referenceDir = fullfile(root,'references','mathworks','R2026a');
    helper = fullfile(referenceDir,'HARQEntity.m');
    if ~isfile(helper)
        fprintf('Retrieving official R2026a HARQ example (internet required once)...\n');
        if ~isfolder(fileparts(referenceDir)), mkdir(fileparts(referenceDir)); end
        try
            setupExample(exampleId,referenceDir);
        catch cause
            err = MException('HARQ:ReferenceDownload', ...
                ['Could not retrieve the MathWorks example. With internet access, run:\n' ...
                 'openExample(''%s'',workDir=''%s'')\nThen rerun the experiment.'], ...
                exampleId,referenceDir);
            throwAsCaller(addCause(err,cause));
        end
    end
    addpath(referenceDir,'-begin');
    if ~strcmpi(which('HARQEntity'),helper)
        error('HARQ:HelperShadowed','Another HARQEntity is shadowing %s. Clear it from the path.',helper);
    end
    environment.MATLAB = version;
    environment.Release = version('-release');
    environment.Toolboxes = ver;
    environment.ReferenceExample = exampleId;
    environment.ReferenceURL = 'https://www.mathworks.com/help/5g/gs/model-5g-nr-transport-channels-with-harq.html';
    environment.HelperPath = helper;
    environment.Model = 'NR DL-SCH/PDSCH symbols over AWGN; no OFDM/fading/control waveform';
    environment.Feedback = 'Ideal CRC feedback; fixed cyclic process scheduling';
end
