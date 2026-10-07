function output = experiment_02_harq(mode, overrides)
%EXPERIMENT_02_HARQ Run Person 2's reproducible R2026a HARQ experiment.
% From the repository root: addpath('experiments'); experiment_02_harq
% experiment_02_harq("study") runs the larger, multi-seed sweep.
% cfg overrides: experiment_02_harq("quick",struct('ShowFigures',false))
    arguments
        mode (1,1) string {mustBeMember(mode,["quick","study"])} = "quick"
        overrides (1,1) struct = struct()
    end
    environment = setupHarqExperiment();
    cfg = harqExperimentConfig(mode);
    fields = fieldnames(overrides);
    for k = 1:numel(fields)
        if ~isfield(cfg,fields{k})
            error('HARQ:UnknownSetting','Unknown experiment setting: %s',fields{k});
        end
        cfg.(fields{k}) = overrides.(fields{k});
    end
    assert(numel(cfg.RVSequences)==numel(cfg.Labels) && ...
        numel(unique(cfg.Labels))==numel(cfg.Labels),'HARQ:Labels', ...
        'Provide one unique label for each RV sequence.');
    validateattributes(cfg.SNRdB,{'numeric'},{'vector','nonempty','real','finite'});
    validateattributes(cfg.Seeds,{'numeric'},{'vector','nonempty','integer','nonnegative','<=',2^32-1});
    assert(numel(unique(cfg.Seeds))==numel(cfg.Seeds),'HARQ:Seeds','Seeds must be unique.');
    root = fileparts(fileparts(mfilename('fullpath')));
    runDir = "";
    figureDir = "";
    if cfg.SaveResults
        dataRoot = fullfile(root,'results','data');
        if ~isfolder(dataRoot), mkdir(dataRoot); end
        [~,suffix] = fileparts(tempname(dataRoot));
        runName = sprintf('harq_%s_%s_%s',mode,char(datetime('now','Format','yyyyMMdd_HHmmss')),suffix);
        runDir = fullfile(dataRoot,runName);
        figureDir = fullfile(root,'results','figures',runName);
        mkdir(runDir); mkdir(figureDir);
        save(fullfile(runDir,'manifest.mat'),'cfg','environment');
        copyfile(environment.HelperPath,fullfile(runDir,'HARQEntity.m'));
    end
    total = numel(cfg.Labels)*numel(cfg.SNRdB)*numel(cfg.Seeds);
    results = cell(total,1);
    rows = cell(total,1);
    runIndex = 0;
    fprintf('%s mode: %d runs, %d new TBs per run. SNR is symbol Es/N0.\n', ...
        mode,total,cfg.NumTransportBlocks);
    for configIndex = 1:numel(cfg.Labels)
        for snrIndex = 1:numel(cfg.SNRdB)
            for seedIndex = 1:numel(cfg.Seeds)
                runIndex = runIndex+1;
                scenario = struct('SNRdB',cfg.SNRdB(snrIndex), ...
                    'Seed',cfg.Seeds(seedIndex),'RVSequence',cfg.RVSequences{configIndex});
                result = runHarqLinkSimulation(cfg,scenario);
                m = result.metrics;
                row = struct('configuration',string(cfg.Labels(configIndex)), ...
                    'snrDb',scenario.SNRdB,'seed',scenario.Seed, ...
                    'maxAttempts',numel(scenario.RVSequence));
                metricNames = fieldnames(m);
                for j = 1:numel(metricNames), row.(metricNames{j}) = m.(metricNames{j}); end
                rows{runIndex} = struct2table(row);
                results{runIndex} = result;
                if cfg.SaveResults
                    stem = sprintf('config%02d_snr%02d_seed%02d',configIndex,snrIndex,seedIndex);
                    save(fullfile(runDir,[stem '.mat']),'result');
                    writetable(result.raw.events,fullfile(runDir,[stem '_events.csv']));
                end
                fprintf('[%d/%d] %s, SNR=%g dB, seed=%d: first BLER=%.3f, final=%.3f, %.3f Mbit/s\n', ...
                    runIndex,total,cfg.Labels(configIndex),scenario.SNRdB,scenario.Seed, ...
                    m.firstTransmissionBLER,m.finalResidualBLER,m.goodputBitsPerSecond/1e6);
            end
        end
    end
    perRun = vertcat(rows{:});
    summary = summarizeHarqRuns(perRun);
    if cfg.SaveResults
        writetable(perRun,fullfile(runDir,'per_run.csv'));
        writetable(summary,fullfile(runDir,'summary.csv'));
        save(fullfile(runDir,'summary.mat'),'cfg','environment','perRun','summary');
    end
    plotHarqExperiment(summary,figureDir,cfg.ShowFigures,mode);
    output = struct('cfg',cfg,'environment',environment,'perRun',perRun, ...
        'summary',summary,'results',{results},'dataDirectory',runDir,'figureDirectory',figureDir);
    if cfg.SaveResults, fprintf('Saved data: %s\nSaved figures: %s\n',runDir,figureDir); end
    if mode == "quick"
        fprintf('QUICK PILOT: validate settings and sample size before using results in the report.\n');
    end
end
