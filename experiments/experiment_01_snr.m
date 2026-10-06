%% Experiment 1 - SNR Sweep
% Owner: Person 1
%
% Purpose:
% Study how Signal-to-Noise Ratio (SNR) changes HARQ behavior.
%
% This version is a fast development sweep for MATLAB R2022a.
% The longer report-quality sweep can be restored later once runtime is known.

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot,"src")));

cfg = defaultConfig();

% Fast development run.
cfg.NumTransportBlocks = 50;

% Avoid the very low-SNR points for now because they trigger many HARQ
% attempts and make the LDPC encoder/decoder run much longer.
snrValues = 0:2:12;

results = cell(1,numel(snrValues));

firstAttemptBLER = zeros(size(snrValues));
finalFailureRate = zeros(size(snrValues));
averageTransmissionAttempts = zeros(size(snrValues));
averageRetransmissionsPerBlock = zeros(size(snrValues));

fprintf("\n5G NR HARQ SNR development sweep\n");
fprintf("Transport blocks per SNR: %d\n",cfg.NumTransportBlocks);
fprintf("------------------------------------------------------------\n");

for idx = 1:numel(snrValues)

    scenario.SNRdB = snrValues(idx);

    fprintf("Running SNR = %g dB ...\n",scenario.SNRdB);
    drawnow;

    results{idx} = runSimulation(cfg,scenario);

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

    fprintf("  first-attempt BLER                : %6.2f%%\n", ...
        firstAttemptBLER(idx)*100);
    fprintf("  final HARQ failure rate           : %6.2f%%\n", ...
        finalFailureRate(idx)*100);
    fprintf("  average transmission attempts     : %.2f\n", ...
        averageTransmissionAttempts(idx));
    fprintf("  average retransmissions per block : %.2f\n\n", ...
        averageRetransmissionsPerBlock(idx));
end

%% Plot 1 - First-attempt BLER and final HARQ failure rate

figure;
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

figure;
plot(snrValues,averageTransmissionAttempts,"-o","LineWidth",1.5);
grid on;
xlabel("Signal-to-Noise Ratio (dB)");
ylabel("Average transmission attempts per transport block");
title("Average HARQ Transmission Attempts vs SNR");

%% Plot 3 - Average retransmissions

figure;
plot(snrValues,averageRetransmissionsPerBlock,"-o","LineWidth",1.5);
grid on;
xlabel("Signal-to-Noise Ratio (dB)");
ylabel("Average retransmissions per transport block");
title("Average HARQ Retransmissions vs SNR");

%% Save raw sweep data for later inspection

dataDirectory = fullfile(repoRoot,"results","data");
if ~exist(dataDirectory,"dir")
    mkdir(dataDirectory);
end

save(fullfile(dataDirectory,"experiment_01_snr_results.mat"), ...
    "snrValues", ...
    "results", ...
    "firstAttemptBLER", ...
    "finalFailureRate", ...
    "averageTransmissionAttempts", ...
    "averageRetransmissionsPerBlock", ...
    "cfg");

fprintf("Saved sweep data to results/data/experiment_01_snr_results.mat\n");

% Later report-quality run:
% - increase NumTransportBlocks substantially
% - reintroduce lower SNR values if needed
% - justify final SNR range
% - confirm final metric definitions with Person 2
