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

SNRdB = 5;
SNR = 10^(SNRdB/10);

ofdmInfo = nrOFDMInfo(carrier);
N0 = 1/sqrt(2*double(ofdmInfo.Nfft)*SNR);

noise = N0*complex(randn(size(waveform)), randn(size(waveform)));
rxWaveformNoisy = waveform + noise;

rxGridNoisy = nrOFDMDemodulate(carrier, rxWaveformNoisy);
rxSymbolsNoisy = rxGridNoisy(pdschInd);

measuredNoiseVar = mean(abs(rxSymbolsNoisy - symbols).^2)
expectedNoiseVar = 1/SNR

