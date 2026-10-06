%% Experiment 1 - SNR Sweep
% Owner: Person 1
%
% Purpose:
% Study how Signal-to-Noise Ratio (SNR) changes HARQ behavior.
%
% This is our first larger sweep after the 20-block smoke test.
% The range and run length are still provisional until the group justifies
% them for the final report.

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot,"src")));

cfg = defaultConfig();

% Use more transport blocks than the smoke test so trends are less dependent
% on a very small sample. Increase later if runtime and convergence allow.
cfg.NumTransportBlocks = 500;

% Provisional sweep chosen to expose poor, intermediate, and good conditions.
snrValues = -4:2:12;

results = cell(1,numel(snrValues));

firstAttemptBLER = zeros(size(snrValues));
finalFailureRate = zeros(size(snrValues));
averageTransmissionAttempts = zeros(size(snrValues));
averageRetransmissionsPerBlock = zeros(size(snrValues));

fprintf("\n5G NR HARQ SNR sweep\n");
fprintf("Transport blocks per SNR: %d\n",cfg.NumTransportBlocks);
fprintf("------------------------------------------------------------\n");

for idx = 1:numel(snrValues)

    scenario.SNRdB = snrValues(idx);
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

    fprintf("SNR = %4g dB | first BLER = %6.2f%% | final fail = %6.2f%% | avg attempts = %.2f | avg retx = %.2f\n", ...
        scenario.SNRdB, ...
        firstAttemptBLER(idx)*100, ...
        finalFailureRate(idx)*100, ...
        averageTransmissionAttempts(idx), ...
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

fprintf("\nSaved sweep data to results/data/experiment_01_snr_results.mat\n");

% Next:
% - inspect whether 500 blocks are enough for stable curves
% - justify the final SNR range from literature/reference behavior
% - agree with Person 2 on final metric definitions
% - repeat with a larger run if the curves remain noisy
