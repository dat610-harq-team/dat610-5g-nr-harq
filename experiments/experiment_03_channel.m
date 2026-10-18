%% Experiment 3 - channel conditions
% Owner: Person 3
%
% Question: How do verified channel conditions affect HARQ outcomes?
%
% Rydd og gjør klar (clear, ensureHarqReference, cfg=defaultConfig)
clear;
ensureHarqReference();
cfg = defaultConfig();
cfg.NumTransportBlocks = 1000;

%Bestem hva som skal varieres:
channelTypes = {'AWGN', 'TDL-C'};
snrValues = 4:1:16;
seeds = [610,611,612];
rvSequence = [0 2 3 1];

% Sett felles kanalinnstillinger (delay spread, Doppler)
channelBase.DelaySpread = 300e-9;
channelBase.MaximumDopplerShift = 5;

% Lag et tomt sted å lagre resultatene, numel betyr antall elementer
nC = numel(channelTypes);
perRunRows = {};

% Løkke over kanaler, SNR og seeds:
for c = 1:nC
    for s = 1:numel(snrValues)
        for k = 1:numel(seeds)
            scenario = struct();
            scenario.SNRdB = snrValues(s);
            scenario.Seed = seeds(k);
            scenario.RVSequence = rvSequence;
            scenario.Channel = channelBase;
            scenario.Channel.channelType = channelTypes{c};

            result = runHarqLinkSimulation(cfg, scenario);

            row = struct2table(result.metrics);
            row.configuration = string(channelTypes{c});
            row.snrDb = snrValues(s);
            row.seed = seeds(k);
            row.maxAttempts = numel(rvSequence);
            perRunRows{end+1,1} = row;
        end
    end
end

% Slå sammen seedene
perRun = vertcat(perRunRows{:});
summary = summarizeHarqRuns(perRun);

% Plott
markers = {'-o', '-s'};

%figur 1, feil på første forsøk med 95% kondifendsintervall
fig1 = figure('Color', 'w');
hold on;
for c = 1:nC
    sel = summary.configuration == string(channelTypes{c});
    x = summary.snrDb(sel);
    y = summary.firstTransmissionBLER(sel);
    lo = summary.firstBLERLow95(sel);
    hi = summary.firstBLERHigh95(sel);
    errorbar(x, y, y-lo, hi-y, markers{c}, 'LineWidth', 1.5);
end
hold off;
xlabel('PDSCH symbol E_s/N_0 (dB)');
ylabel('First-transmission BLER');
legend(channelTypes, 'Location', 'northeast');
grid on;
set(gca, 'FontSize', 12);

%figur 2, goodput
fig2 = figure('Color', 'w');
hold on;
for c = 1:nC
    sel = summary.configuration == string(channelTypes{c});
    plot(summary.snrDb(sel), summary.goodputMbps(sel), markers{c}, 'LineWidth', 1.5);
end
hold off;
xlabel('PDSCH symbol E_s/N_0 (dB)');
ylabel('Goodput (Mbit/s)');
legend(channelTypes, 'Location', 'southeast');
grid on;
set(gca, 'FontSize', 12);

%figur 3, gjennomsnittlig antall retransmisjoner per levert blokk
fig3= figure('Color', 'w');
hold on;
for c = 1:nC;
    sel = summary.configuration == string(channelTypes{c});
    x = summary.snrDb(sel);
    y = summary.meanRetransmissionsPerDeliveredTb(sel);
    lo = summary.meanRetxLow95(sel);
    hi = summary.meanRetxHigh95(sel);
    errorbar(x, y, y-lo, hi-y, markers{c}, 'LineWidth', 1.5);
end
hold off;
xlabel('PDSCH symbol E_s/N_0 (dB)');
ylabel('Mean retransmissions per delivered TB');
legend(channelTypes, 'Location', 'northeast');
grid on;
set(gca, 'FontSize', 12);
% Lagre figurene som PDF
outDir = fullfile('results', 'experiment_03');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
exportgraphics(fig1, fullfile(outDir, 'first_bler_vs_snr.pdf'));
exportgraphics(fig2, fullfile(outDir, 'goodput_vs_snr.pdf'));
exportgraphics(fig3, fullfile(outDir, 'retransmission_vs_snr.pdf'));
writetable(summary, fullfile(outDir, 'summary.csv'));
