cfg = defaultConfig();

carrier = nrCarrierConfig;
carrier.NSizeGrid = cfg.NSizeGrid;
carrier.SubcarrierSpacing = cfg.SubcarrierSpacing;
carrier.CyclicPrefix = cfg.CyclicPrefix;

pdsch = nrPDSCHConfig;
pdsch.Modulation = cfg.Modulation;
pdsch.NumLayers = cfg.NumLayers;
pdsch.PRBSet = 0:cfg.NSizeGrid-1;
%pdsch.PRBSet = cfg.PRBSet;

[pdschInd, pdschInfo] = nrPDSCHIndices(carrier, pdsch);

%Lage testsymboler
bits = randi([0 1], pdschInfo.G, 1);
symbols = nrPDSCH(carrier, pdsch, bits);

%Lage et tomt grid og plassere symbolene
grid = nrResourceGrid(carrier);
grid(pdschInd) = symbols;

%OFDM moduler, grid -> bølge
waveform = nrOFDMModulate(carrier, grid);

%OFDM demoduler, bølge -> grid
rxGrid = nrOFDMDemodulate(carrier, waveform);

%Hent symbolene ut fra samme ruter
rxSymbols = rxGrid(pdschInd);

%Sammenlign
maxError = max(abs(rxSymbols - symbols))

%% Støy i bølgen

SNRdB = 40;
SNR = 10^(SNRdB/10);

ofdmInfo = nrOFDMInfo(carrier);
N0 = 1/sqrt(2*double(ofdmInfo.Nfft)*SNR);

noise = N0*complex(randn(size(waveform)), randn(size(waveform)));
rxWaveformNoisy = waveform + noise;

rxGridNoisy = nrOFDMDemodulate(carrier, rxWaveformNoisy);
rxSymbolsNoisy = rxGridNoisy(pdschInd);

measuredNoiseVar = mean(abs(rxSymbolsNoisy - symbols).^2)
expectedNoiseVar = 1/SNR

%% TDL kanal

chCfg.channelType = 'TDL-C';
chCfg.DelaySpread = 300e-9;
chCfg.MaximumDopplerShift = 5;
chCfg.NTxAnts = 1;
chCfg.NRxAnts = 1;
chCfg.SampleRate = ofdmInfo.SampleRate; %Dette er den ekte sampleraten.

ch = createChannel(chCfg);
[rxWaveformTDL, pathGains, sampleTimes] = applyChannel(ch, waveform);

size(waveform)
size(rxWaveformTDL)
size(pathGains)

%% TDL kanal Støy

noiseTDL = N0*complex(randn(size(rxWaveformTDL)), randn(size(rxWaveformTDL)));
rxWaveformTDL = rxWaveformTDL + noiseTDL;

%Finn hvor signalet faktisk starter
pathFilters = getPathFilters(ch.object);
offset = nrPerfectTimingEstimate(pathGains, pathFilters)
rxWaveformTDL = rxWaveformTDL(1+offset:end, :);

%Pakk ut bølgen
rxGridTDL = nrOFDMDemodulate(carrier, rxWaveformTDL);
size(rxGridTDL)

%% Hva gjorde stormen med hver rute

%Perfekt kanalestimat
H = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);

%Hent data-rutene, både mottatte symboler og kanalen
[rxSymTDL, Hpdsch] = nrExtractResources(pdschInd, rxGridTDL, H);

%Rett opp det kanalen gjorde
noiseVar = 1/SNR;
[eqSymTDL, csi] = nrEqualizeMMSE(rxSymTDL, Hpdsch, noiseVar);

%Hvor langt unna originalen er de rettede symbolene?
errTDL = mean(abs(eqSymTDL - symbols).^2)
