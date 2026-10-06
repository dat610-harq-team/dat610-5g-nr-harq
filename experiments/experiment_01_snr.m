%% Experiment 1 - SNR Sweep
% Owner: Person 1
%
% Purpose:
% Study how Signal-to-Noise Ratio (SNR) changes HARQ behavior.
%
% This is the first serious experiment run after the smoke/development tests.
% The settings are still provisional until the group justifies the final
% parameter choices for the report.

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot,"src")));

cfg = defaultConfig();

% Larger run for more stable estimates than the 20- and 50-block tests.
cfg.NumTransportBlocks = 300;

% Keep broad coverage, but add finer resolution around the transition region
% where the earlier development sweep changed sharply.
snrValues = [2 4 5 5.5 6 6.5 7 7.5 8 8.5 9 10 12];

results = cell(1,numel(snrValues));

firstAttemptBLER = zeros(size(snrValues));
finalFailureRate = zeros(size(snrValues));
averageTransmissionAttempts = zeros(size(snrValues));
averageRetransmissionsPerBlock = zeros(size(snrValues));
harqRecoveredBlocks = zeros(size(snrValues));
elapsedSeconds = zeros(size(snrValues));

fprintf("\n5G NR HARQ SNR experiment\n");
fprintf("Transport blocks per SNR: %d\n",cfg.NumTransportBlocks);
fprintf("SNR points: %d\n",numel(snrValues));
fprintf("------------------------------------------------------------\n");

for idx = 1:numel(snrValues)

    scenario.SNRdB = snrValues(idx);

    fprintf("Running SNR = %g dB ...\n",scenario.SNRdB);
    drawnow;

    runTimer = tic;
    results{idx} = runSimulation(cfg,scenario);
    elapsedSeconds(idx) = toc(runTimer);

    raw = results{idx}.raw;

    firstAttemptFailures = sum(raw.firstAttemptBlockError);

    firstAttemptBLER(idx) = ...
        firstAttemptFailures / raw.totalTransportBlocks;

    finalFailureRate(idx) = ...
        raw.finalFailedTransportBlocks / raw.totalTransportBlocks;

    averageTransmissionAttempts(idx) = ...
        raw.totalTransmissionAttempts / raw.totalTransportBlocks;

    averageRetransmissionsPerBlock(idx) = ...
        raw.totalRetransmissions / raw.totalTransportBlocks;

    % Blocks that failed on the first attempt but eventually succeeded.
    harqRecoveredBlocks(idx) = ...
        firstAttemptFailures - raw.finalFailedTransportBlocks;

    fprintf("  first-attempt failures            : %d\n",firstAttemptFailures);
    fprintf("  first-attempt BLER                : %6.2f%%\n", ...
        firstAttemptBLER(idx)*100);
    fprintf("  HARQ-recovered blocks             : %d\n", ...
        harqRecoveredBlocks(idx));
    fprintf("  final HARQ failure rate           : %6.2f%%\n", ...
        finalFailureRate(idx)*100);
    fprintf("  average transmission attempts     : %.3f\n", ...
        averageTransmissionAttempts(idx));
    fprintf("  average retransmissions per block : %.3f\n", ...
        averageRetransmissionsPerBlock(idx));
    fprintf("  runtime                           : %.1f s\n\n", ...
        elapsedSeconds(idx));
end

%% Create summary table

summaryTable = table( ...
    snrValues(:), ...
    firstAttemptBLER(:), ...
    finalFailureRate(:), ...
    harqRecoveredBlocks(:), ...
    averageTransmissionAttempts(:), ...
    averageRetransmissionsPerBlock(:), ...
    elapsedSeconds(:), ...
    'VariableNames',{ ...
        'SNRdB', ...
        'FirstAttemptBLER', ...
        'FinalHARQFailureRate', ...
        'HARQRecoveredBlocks', ...
        'AverageTransmissionAttempts', ...
        'AverageRetransmissionsPerBlock', ...
        'RuntimeSeconds'});

disp(summaryTable);

%% Prepare output directories

dataDirectory = fullfile(repoRoot,"results","data");
figureDirectory = fullfile(repoRoot,"results","figures");

if ~exist(dataDirectory,"dir")
    mkdir(dataDirectory);
end

if ~exist(figureDirectory,"dir")
    mkdir(figureDirectory);
end

%% Plot 1 - First-attempt BLER and final HARQ failure rate

figure1 = figure;
plot(snrValues,firstAttemptBLER,"-o","LineWidth",1.5);
hold on;
plot(snrValues,finalFailureRate,"-s","LineWidth",1.5);
hold off;
grid on;
xlabel("Signal-to-Noise Ratio (dB)");
ylabel("Rate");
title("Block Failure Behavior vs SNR");
legend("First-attempt BLER","Final HARQ failure rate","Location","best");

%% Plot 2 - Average transmission attempts

figure2 = figure;
plot(snrValues,averageTransmissionAttempts,"-o","LineWidth",1.5);
grid on;
xlabel("Signal-to-Noise Ratio (dB)");
ylabel("Average transmission attempts per transport block");
title("Average HARQ Transmission Attempts vs SNR");

%% Plot 3 - Average retransmissions

figure3 = figure;
plot(snrValues,averageRetransmissionsPerBlock,"-o","LineWidth",1.5);
grid on;
xlabel("Signal-to-Noise Ratio (dB)");
ylabel("Average retransmissions per transport block");
title("Average HARQ Retransmissions vs SNR");

%% Save experiment outputs

save(fullfile(dataDirectory,"experiment_01_snr_results.mat"), ...
    "snrValues", ...
    "results", ...
    "firstAttemptBLER", ...
    "finalFailureRate", ...
    "harqRecoveredBlocks", ...
    "averageTransmissionAttempts", ...
    "averageRetransmissionsPerBlock", ...
    "elapsedSeconds", ...
    "summaryTable", ...
    "cfg");

writetable(summaryTable, ...
    fullfile(dataDirectory,"experiment_01_snr_summary.csv"));

saveas(figure1,fullfile(figureDirectory,"experiment_01_bler_vs_snr.png"));
saveas(figure2,fullfile(figureDirectory,"experiment_01_attempts_vs_snr.png"));
saveas(figure3,fullfile(figureDirectory,"experiment_01_retransmissions_vs_snr.png"));

fprintf("\nSaved raw data, CSV summary, and figures under results/.\n");

% Before treating these as final report results:
% - inspect curve stability
% - decide whether 300 blocks are sufficient
% - justify final SNR range from literature/reference behavior
% - confirm final metric definitions with Person 2
