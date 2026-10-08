%% Experiment 1 - SNR Sweep
% Owner: Person 1
%
% Uses the shared runSimulation entry point and Person 2's event/metric model.

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot,"src")));

cfg = defaultConfig();
cfg.NumTransportBlocks = 300;

% Broad coverage plus finer resolution near the transition observed earlier.
snrValues = [2 4 5 5.5 6 6.5 7 7.5 8 8.5 9 10 12];

results = cell(1,numel(snrValues));

firstTransmissionBLER = zeros(size(snrValues));
finalResidualBLER = zeros(size(snrValues));
goodputMbps = zeros(size(snrValues));
meanAttemptsPerDeliveredTb = zeros(size(snrValues));
meanRetransmissionsPerDeliveredTb = zeros(size(snrValues));
retransmissionProbability = zeros(size(snrValues));
meanDeliveryLatencySlots = zeros(size(snrValues));
runtimeSeconds = zeros(size(snrValues));

fprintf("\n5G NR HARQ SNR experiment - integrated event model\n");
fprintf("Transport blocks per SNR: %d\n",cfg.NumTransportBlocks);
fprintf("HARQ processes: %d\n",cfg.NHARQProcesses);
fprintf("RV sequence: [%s]\n",num2str(cfg.RVSequence));
fprintf("------------------------------------------------------------\n");

for idx = 1:numel(snrValues)

    scenario.SNRdB = snrValues(idx);
    scenario.Seed = cfg.Seed;
    scenario.RVSequence = cfg.RVSequence;

    fprintf("Running SNR = %g dB ...\n",scenario.SNRdB);
    drawnow;

    runTimer = tic;
    results{idx} = runSimulation(cfg,scenario);
    runtimeSeconds(idx) = toc(runTimer);

    metrics = results{idx}.metrics;

    firstTransmissionBLER(idx) = metrics.firstTransmissionBLER;
    finalResidualBLER(idx) = metrics.finalResidualBLER;
    goodputMbps(idx) = metrics.goodputBitsPerSecond / 1e6;
    meanAttemptsPerDeliveredTb(idx) = metrics.meanAttemptsPerDeliveredTb;
    meanRetransmissionsPerDeliveredTb(idx) = ...
        metrics.meanRetransmissionsPerDeliveredTb;
    retransmissionProbability(idx) = metrics.retransmissionProbability;
    meanDeliveryLatencySlots(idx) = metrics.meanDeliveryLatencySlots;

    fprintf("  first-transmission BLER           : %6.2f%%\n", ...
        firstTransmissionBLER(idx)*100);
    fprintf("  final residual BLER               : %6.2f%%\n", ...
        finalResidualBLER(idx)*100);
    fprintf("  delivered transport blocks        : %d / %d\n", ...
        metrics.deliveredTransportBlocks,metrics.observedTransportBlocks);
    fprintf("  goodput                            : %.3f Mbit/s\n", ...
        goodputMbps(idx));
    fprintf("  mean attempts per delivered TB     : %.3f\n", ...
        meanAttemptsPerDeliveredTb(idx));
    fprintf("  mean retransmissions per delivered : %.3f\n", ...
        meanRetransmissionsPerDeliveredTb(idx));
    fprintf("  retransmission probability         : %.3f\n", ...
        retransmissionProbability(idx));
    fprintf("  mean delivery latency              : %.3f slots\n", ...
        meanDeliveryLatencySlots(idx));
    fprintf("  MATLAB runtime                     : %.1f s\n\n", ...
        runtimeSeconds(idx));
end

%% Summary table

summaryTable = table( ...
    snrValues(:), ...
    firstTransmissionBLER(:), ...
    finalResidualBLER(:), ...
    goodputMbps(:), ...
    meanAttemptsPerDeliveredTb(:), ...
    meanRetransmissionsPerDeliveredTb(:), ...
    retransmissionProbability(:), ...
    meanDeliveryLatencySlots(:), ...
    runtimeSeconds(:), ...
    'VariableNames',{ ...
        'SNRdB', ...
        'FirstTransmissionBLER', ...
        'FinalResidualBLER', ...
        'GoodputMbps', ...
        'MeanAttemptsPerDeliveredTb', ...
        'MeanRetransmissionsPerDeliveredTb', ...
        'RetransmissionProbability', ...
        'MeanDeliveryLatencySlots', ...
        'RuntimeSeconds'});

disp(summaryTable);

%% Output directories

dataDirectory = fullfile(repoRoot,"results","data");
figureDirectory = fullfile(repoRoot,"results","figures");

if ~exist(dataDirectory,"dir"), mkdir(dataDirectory); end
if ~exist(figureDirectory,"dir"), mkdir(figureDirectory); end

%% Figures

figure1 = figure;
plot(snrValues,firstTransmissionBLER,"-o","LineWidth",1.5);
hold on;
plot(snrValues,finalResidualBLER,"-s","LineWidth",1.5);
hold off;
grid on;
xlabel("PDSCH symbol E_s/N_0 (dB)");
ylabel("Block error rate");
legend("First transmission","After HARQ","Location","best");

figure2 = figure;
plot(snrValues,goodputMbps,"-o","LineWidth",1.5);
grid on;
xlabel("PDSCH symbol E_s/N_0 (dB)");
ylabel("Goodput (Mbit/s)");

figure3 = figure;
plot(snrValues,meanRetransmissionsPerDeliveredTb,"-o","LineWidth",1.5);
grid on;
xlabel("PDSCH symbol E_s/N_0 (dB)");
ylabel("Mean retransmissions per delivered TB");

figure4 = figure;
plot(snrValues,meanDeliveryLatencySlots,"-o","LineWidth",1.5);
grid on;
xlabel("PDSCH symbol E_s/N_0 (dB)");
ylabel("Mean delivery latency (slots)");

%% Save

save(fullfile(dataDirectory,"experiment_01_snr_integrated.mat"), ...
    "snrValues","results","summaryTable","cfg");

writetable(summaryTable, ...
    fullfile(dataDirectory,"experiment_01_snr_integrated.csv"));

saveas(figure1,fullfile(figureDirectory,"experiment_01_bler_vs_snr.png"));
saveas(figure2,fullfile(figureDirectory,"experiment_01_goodput_vs_snr.png"));
saveas(figure3,fullfile(figureDirectory,"experiment_01_retransmissions_vs_snr.png"));
saveas(figure4,fullfile(figureDirectory,"experiment_01_latency_vs_snr.png"));

fprintf("\nSaved integrated SNR results under results/.\n");
