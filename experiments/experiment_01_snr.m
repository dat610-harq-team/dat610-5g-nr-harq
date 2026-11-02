function output = experiment_01_snr(mode, overrides)
%EXPERIMENT_01_SNR Person 1's reproducible SNR study using the shared HARQ engine.
%
%   experiment_01_snr
%       Quick broad pilot: 300 TBs, one seed.
%
%   experiment_01_snr("study")
%       Final-style transition study: 1000 TBs per run, three seeds,
%       fine 0.25 dB spacing from 6 to 8 dB.
%
%   experiment_01_snr("low-snr-pilot")
%       Small exploratory sweep used only to locate the region where
%       residual HARQ failures begin.
%
%   experiment_01_snr("low-snr-study")
%       Final-style lower-transition study: 1000 TBs per run, three seeds,
%       fine 0.25 dB spacing from -1 to 0.5 dB.
%
%   experiment_01_snr(mode, overrides)
%       Override experiment settings, for example:
%       experiment_01_snr("study",struct("NumTransportBlocks",500))
%
% The radio/HARQ implementation is not changed here. This file only controls
% repeated runs, aggregation, uncertainty reporting, plotting and saving.

    arguments
        mode (1,1) string {mustBeMember(mode,["quick","study","low-snr-pilot","low-snr-study"])} = "quick"
        overrides (1,1) struct = struct()
    end

    repoRoot = fileparts(fileparts(mfilename("fullpath")));
    addpath(genpath(fullfile(repoRoot,"src")));

    cfg = defaultConfig();

    % Experiment-only settings. Keep these separate from the shared link cfg.
    switch mode
        case "quick"
            snrValues = [2 4 5 5.5 6 6.5 7 7.5 8 8.5 9 10 12];
            seeds = 610;
            cfg.NumTransportBlocks = 300;
        case "study"
            snrValues = 6:0.25:8;
            seeds = [610 611 612];
            cfg.NumTransportBlocks = 1000;
        case "low-snr-pilot"
            snrValues = [-2 -1 0 1 2 3 4];
            seeds = 610;
            cfg.NumTransportBlocks = 200;
        case "low-snr-study"
            snrValues = -1:0.25:0.5;
            seeds = [610 611 612];
            cfg.NumTransportBlocks = 1000;
    end

    % Optional user overrides without changing the shared default configuration.
    if isfield(overrides,"SNRdB"), snrValues = overrides.SNRdB; end
    if isfield(overrides,"Seeds"), seeds = overrides.Seeds; end
    if isfield(overrides,"NumTransportBlocks")
        cfg.NumTransportBlocks = overrides.NumTransportBlocks;
    end
    if isfield(overrides,"ShowProgress"), cfg.ShowProgress = overrides.ShowProgress; end
    if isfield(overrides,"ProgressEvery"), cfg.ProgressEvery = overrides.ProgressEvery; end

    allowed = ["SNRdB","Seeds","NumTransportBlocks","ShowProgress","ProgressEvery"];
    supplied = string(fieldnames(overrides));
    unknown = setdiff(supplied,allowed);
    if ~isempty(unknown)
        error('SNR:UnknownSetting','Unknown experiment setting: %s',strjoin(unknown,", "));
    end

    validateattributes(snrValues,{'numeric'},{'vector','nonempty','real','finite'});
    validateattributes(seeds,{'numeric'},{'vector','nonempty','integer','nonnegative','<=',2^32-1});
    assert(numel(unique(seeds))==numel(seeds),'SNR:Seeds','Seeds must be unique.');

    ensureHarqReference();

    environment = struct();
    environment.MATLAB = version;
    environment.Release = version("-release");
    environment.Toolboxes = ver;
    environment.HARQEntity = which("HARQEntity");
    environment.SNRDefinition = "PDSCH symbol Es/N0 (dB)";

    totalRuns = numel(snrValues)*numel(seeds);
    results = cell(totalRuns,1);
    rows = cell(totalRuns,1);
    runIndex = 0;

    fprintf("\n");
    fprintf("+==========================================================+\n");
    fprintf("|              5G NR HARQ SNR EXPERIMENT                 |\n");
    fprintf("+==========================================================+\n");
    fprintf("| Mode             : %-36s |\n",char(mode));
    fprintf("| SNR points       : %-36d |\n",numel(snrValues));
    fprintf("| Seeds            : %-36d |\n",numel(seeds));
    fprintf("| Total runs       : %-36d |\n",totalRuns);
    fprintf("| TBs per run      : %-36d |\n",cfg.NumTransportBlocks);
    fprintf("| HARQ processes   : %-36d |\n",cfg.NHARQProcesses);
    fprintf("| RV sequence      : [%-33s] |\n",strtrim(num2str(cfg.RVSequence)));
    fprintf("| Modulation       : %-36s |\n",char(cfg.Modulation));
    fprintf("| Code rate        : %-36.3f |\n",cfg.TargetCodeRate);
    fprintf("| SCS              : %-32g kHz |\n",cfg.SubcarrierSpacing);
    fprintf("+----------------------------------------------------------+\n");

    % Unique output folder so study runs never overwrite earlier evidence.
    dataRoot = fullfile(repoRoot,"results","data");
    figureRoot = fullfile(repoRoot,"results","figures");
    if ~isfolder(dataRoot), mkdir(dataRoot); end
    if ~isfolder(figureRoot), mkdir(figureRoot); end

    stamp = char(datetime("now","Format","yyyyMMdd_HHmmss"));
    runName = sprintf("snr_%s_%s",char(mode),stamp);
    runDir = fullfile(dataRoot,runName);
    figureDir = fullfile(figureRoot,runName);
    mkdir(runDir);
    mkdir(figureDir);

    save(fullfile(runDir,"manifest.mat"),"cfg","snrValues","seeds","mode","environment");

    for snrIndex = 1:numel(snrValues)
        for seedIndex = 1:numel(seeds)
            runIndex = runIndex+1;

            scenario = struct( ...
                "SNRdB",snrValues(snrIndex), ...
                "Seed",seeds(seedIndex), ...
                "RVSequence",cfg.RVSequence);

            fprintf("\n>> Run %d/%d | SNR %g dB | seed %d\n", ...
                runIndex,totalRuns,scenario.SNRdB,scenario.Seed);
            fprintf("------------------------------------------------------------\n");
            drawnow;

            runTimer = tic;
            result = runSimulation(cfg,scenario);
            runtimeSeconds = toc(runTimer);
            result.runtimeSeconds = runtimeSeconds;

            m = result.metrics;
            row = struct( ...
                "configuration","Full HARQ [0 2 3 1]", ...
                "snrDb",scenario.SNRdB, ...
                "seed",scenario.Seed, ...
                "maxAttempts",numel(scenario.RVSequence), ...
                "runtimeSeconds",runtimeSeconds);

            metricNames = fieldnames(m);
            for j = 1:numel(metricNames)
                row.(metricNames{j}) = m.(metricNames{j});
            end

            rows{runIndex} = struct2table(row);
            results{runIndex} = result;

            % Use character vectors for the filename on older MATLAB releases.
            % With a string-format sprintf, R2022a can keep "stem" as a string;
            % [stem '.mat'] then becomes a two-element string array, which save
            % rejects because the filename must be one text scalar.
            stem = sprintf('snr_%+05.2f_seed_%d',scenario.SNRdB,scenario.Seed);
            stem = strrep(stem,'.','p');
            stem = strrep(stem,'+','pos');
            stem = strrep(stem,'-','neg');
            resultFile = fullfile(char(runDir),[stem '.mat']);
            save(resultFile,'result');

            fprintf("\n  RESULT\n");
            fprintf("  +------------------------------------------------------+\n");
            fprintf("  | First-transmission BLER : %8.3f                    |\n",m.firstTransmissionBLER);
            fprintf("  | Final residual BLER     : %8.3f                    |\n",m.finalResidualBLER);
            fprintf("  | Delivered TBs           : %4d / %-4d               |\n", ...
                m.deliveredTransportBlocks,m.observedTransportBlocks);
            fprintf("  | Goodput                 : %8.3f Mbit/s             |\n",m.goodputBitsPerSecond/1e6);
            fprintf("  | Mean attempts           : %8.3f                    |\n",m.meanAttemptsPerDeliveredTb);
            fprintf("  | Mean retransmissions    : %8.3f                    |\n",m.meanRetransmissionsPerDeliveredTb);
            fprintf("  | Mean delivery latency   : %8.3f slots              |\n",m.meanDeliveryLatencySlots);
            fprintf("  | MATLAB runtime          : %8.1f s                  |\n",runtimeSeconds);
            fprintf("  +------------------------------------------------------+\n");
        end
    end

    perRun = vertcat(rows{:});
    summary = summarizeHarqRuns(perRun);

    % Seed-to-seed variability for continuous metrics. Reliability uncertainty
    % remains the pooled Wilson 95%% interval from summarizeHarqRuns.
    snrs = summary.snrDb;
    meanGoodputAcrossSeeds = NaN(height(summary),1);
    stdGoodputAcrossSeeds = NaN(height(summary),1);
    meanLatencyAcrossSeeds = NaN(height(summary),1);
    stdLatencyAcrossSeeds = NaN(height(summary),1);
    meanRetxAcrossSeeds = NaN(height(summary),1);
    stdRetxAcrossSeeds = NaN(height(summary),1);

    for i = 1:height(summary)
        r = perRun(perRun.snrDb==snrs(i),:);
        g = r.goodputBitsPerSecond/1e6;
        meanGoodputAcrossSeeds(i) = mean(g);
        stdGoodputAcrossSeeds(i) = std(g,0);
        meanLatencyAcrossSeeds(i) = mean(r.meanDeliveryLatencySlots,'omitnan');
        stdLatencyAcrossSeeds(i) = std(r.meanDeliveryLatencySlots,0,'omitnan');
        meanRetxAcrossSeeds(i) = mean(r.meanRetransmissionsPerDeliveredTb,'omitnan');
        stdRetxAcrossSeeds(i) = std(r.meanRetransmissionsPerDeliveredTb,0,'omitnan');
    end

    summary.meanGoodputAcrossSeeds = meanGoodputAcrossSeeds;
    summary.stdGoodputAcrossSeeds = stdGoodputAcrossSeeds;
    summary.meanLatencyAcrossSeeds = meanLatencyAcrossSeeds;
    summary.stdLatencyAcrossSeeds = stdLatencyAcrossSeeds;
    summary.meanRetxAcrossSeeds = meanRetxAcrossSeeds;
    summary.stdRetxAcrossSeeds = stdRetxAcrossSeeds;

    writetable(perRun,fullfile(runDir,"per_run.csv"));
    writetable(summary,fullfile(runDir,"summary.csv"));
    save(fullfile(runDir,"summary.mat"), ...
        "cfg","snrValues","seeds","mode","environment","perRun","summary");

    % ------------------------------------------------------------
    % Report figures
    % ------------------------------------------------------------
    % Format figures for the IEEE report without changing the data:
    % white background, readable axes, no embedded titles, and a light
    % highlight over the SNR region that is most important in each mode.

    [highlightRange,highlightLabel] = snrHighlightRegion(mode);

    % Figure 1: reliability with 95% Wilson confidence intervals.
    f1 = figure("Color","w");
    ax1 = axes(f1);
    hold(ax1,"on");

    errorbar(ax1,summary.snrDb,summary.firstTransmissionBLER, ...
        summary.firstTransmissionBLER-summary.firstBLERLow95, ...
        summary.firstBLERHigh95-summary.firstTransmissionBLER, ...
        "-o","LineWidth",1.8,"MarkerSize",6);

    errorbar(ax1,summary.snrDb,summary.finalResidualBLER, ...
        summary.finalResidualBLER-summary.finalBLERLow95, ...
        summary.finalBLERHigh95-summary.finalResidualBLER, ...
        "-s","LineWidth",1.8,"MarkerSize",6);

    xlabel(ax1,"PDSCH symbol E_s/N_0 (dB)");
    ylabel(ax1,"Block error rate");
    ylim(ax1,[0 1]);
    applyReportStyle(ax1);
    addSNRHighlight(ax1,highlightRange,highlightLabel);
    legend(ax1,"First transmission","After HARQ", ...
        "Location","best","Box","on");
    hold(ax1,"off");

    % Figure 2: goodput. Error bars show seed-to-seed standard deviation.
    f2 = figure("Color","w");
    ax2 = axes(f2);
    hold(ax2,"on");

    errorbar(ax2,summary.snrDb,summary.meanGoodputAcrossSeeds, ...
        summary.stdGoodputAcrossSeeds,"-o", ...
        "LineWidth",1.8,"MarkerSize",6);

    xlabel(ax2,"PDSCH symbol E_s/N_0 (dB)");
    ylabel(ax2,"Goodput (Mbit/s)");
    applyReportStyle(ax2);
    addSNRHighlight(ax2,highlightRange,highlightLabel);
    hold(ax2,"off");

    % Figure 3: retransmissions. Error bars show seed-to-seed std.
    f3 = figure("Color","w");
    ax3 = axes(f3);
    hold(ax3,"on");

    errorbar(ax3,summary.snrDb,summary.meanRetxAcrossSeeds, ...
        summary.stdRetxAcrossSeeds,"-o", ...
        "LineWidth",1.8,"MarkerSize",6);

    xlabel(ax3,"PDSCH symbol E_s/N_0 (dB)");
    ylabel(ax3,"Mean retransmissions per delivered TB");
    applyReportStyle(ax3);
    addSNRHighlight(ax3,highlightRange,highlightLabel);
    hold(ax3,"off");

    % Figure 4: delivery scheduling delay. Error bars show seed-to-seed std.
    f4 = figure("Color","w");
    ax4 = axes(f4);
    hold(ax4,"on");

    errorbar(ax4,summary.snrDb,summary.meanLatencyAcrossSeeds, ...
        summary.stdLatencyAcrossSeeds,"-o", ...
        "LineWidth",1.8,"MarkerSize",6);

    xlabel(ax4,"PDSCH symbol E_s/N_0 (dB)");
    ylabel(ax4,"Mean delivery delay (slots)");
    applyReportStyle(ax4);
    addSNRHighlight(ax4,highlightRange,highlightLabel);
    hold(ax4,"off");

    % Export report-ready PNGs at 300 dpi with an explicit white background.
    exportgraphics(f1,fullfile(figureDir,"bler_vs_snr.png"), ...
        "Resolution",300,"BackgroundColor","white");
    exportgraphics(f2,fullfile(figureDir,"goodput_vs_snr.png"), ...
        "Resolution",300,"BackgroundColor","white");
    exportgraphics(f3,fullfile(figureDir,"retransmissions_vs_snr.png"), ...
        "Resolution",300,"BackgroundColor","white");
    exportgraphics(f4,fullfile(figureDir,"latency_vs_snr.png"), ...
        "Resolution",300,"BackgroundColor","white");

    savefig(f1,fullfile(figureDir,"bler_vs_snr.fig"));
    savefig(f2,fullfile(figureDir,"goodput_vs_snr.fig"));
    savefig(f3,fullfile(figureDir,"retransmissions_vs_snr.fig"));
    savefig(f4,fullfile(figureDir,"latency_vs_snr.fig"));

    fprintf("\n");
    fprintf("+==========================================================+\n");
    fprintf("|                    EXPERIMENT COMPLETE                   |\n");
    fprintf("+==========================================================+\n");
    fprintf("Data    : %s\n",runDir);
    fprintf("Figures : %s\n",figureDir);
    if mode == "quick"
        fprintf("QUICK PILOT: use study mode for final statistical evidence.\n");
    elseif mode == "low-snr-pilot"
        fprintf("LOW-SNR PILOT: use this only to locate the residual-failure region.\n");
    elseif mode == "low-snr-study"
        fprintf("LOW-SNR STUDY: pooled BLER uses Wilson 95%% intervals around the HARQ recovery boundary.\n");
    else
        fprintf("STUDY: pooled BLER uses Wilson 95%% intervals; other error bars show seed variability.\n");
    end

    output = struct( ...
        "cfg",cfg, ...
        "mode",mode, ...
        "snrValues",snrValues, ...
        "seeds",seeds, ...
        "environment",environment, ...
        "perRun",perRun, ...
        "summary",summary, ...
        "results",{results}, ...
        "dataDirectory",runDir, ...
        "figureDirectory",figureDir);
end

function applyReportStyle(ax)
%APPLYREPORTSTYLE Use a simple report-friendly MATLAB figure style.

    ax.Color = "white";
    ax.XColor = "black";
    ax.YColor = "black";
    ax.FontName = "Helvetica";
    ax.FontSize = 11;
    ax.LineWidth = 1.0;
    ax.Box = "on";
    ax.XGrid = "on";
    ax.YGrid = "on";
    ax.GridAlpha = 0.18;
    ax.MinorGridAlpha = 0.10;
    ax.Layer = "top";
end

function [range,label] = snrHighlightRegion(mode)
%SNRHIGHLIGHTREGION Return the important SNR region for each experiment mode.

    switch mode
        case "quick"
            range = [6.5 7.5];
            label = "First-transmission transition";
        case "study"
            range = [6.5 7.5];
            label = "First-transmission transition";
        case "low-snr-pilot"
            range = [-1 0];
            label = "HARQ recovery transition";
        case "low-snr-study"
            range = [-0.75 0];
            label = "HARQ recovery transition";
        otherwise
            range = [];
            label = "";
    end
end

function addSNRHighlight(ax,range,label)
%ADDSNRHIGHLIGHT Lightly shade the important SNR region.

    if isempty(range)
        return;
    end

    yl = ylim(ax);

    region = patch(ax, ...
        [range(1) range(2) range(2) range(1)], ...
        [yl(1) yl(1) yl(2) yl(2)], ...
        [0.75 0.75 0.75], ...
        "FaceAlpha",0.16, ...
        "EdgeColor","none", ...
        "HandleVisibility","off");

    uistack(region,"bottom");

    text(ax,mean(range),yl(2)-0.04*(yl(2)-yl(1)),label, ...
        "HorizontalAlignment","center", ...
        "VerticalAlignment","top", ...
        "FontSize",9, ...
        "Color",[0.25 0.25 0.25], ...
        "HandleVisibility","off");

    ylim(ax,yl);
end

