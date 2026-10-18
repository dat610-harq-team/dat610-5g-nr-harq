function llrs = waveformChannelLink(carrier, pdsch, symbols, ch, noiseVariance, noiseStream)
    %Finn hvor symbolene skal ligge (pdschInd)
    pdschInd = nrPDSCHIndices(carrier, pdsch);

    %Lag et tomt grid og plasser symbolene
    grid = nrResourceGrid(carrier);
    grid(pdschInd) = symbols;

    %OFDM-moduler: grid -> bølge
    waveform = nrOFDMModulate(carrier, grid);

    %Bølgen går gjennom kanalen
    [rxWaveform, pathGains, sampleTimes] = applyChannel(ch, waveform);

    %Den møter på støy
    ofdmInfo = nrOFDMInfo(carrier);
    N0 = sqrt(noiseVariance / (2*double(ofdmInfo.Nfft)));
    
    noise = N0*(randn(noiseStream, size(rxWaveform)) + ...
        1i*randn(noiseStream, size(rxWaveform)));

    rxWaveNoise = noise + rxWaveform;

    %Timing: finn hvor signalet starter, og klipp bort forsinkelsen
    if strcmpi(ch.type, 'AWGN')
        offset = 0;
    
    else
        pathFilters = getPathFilters(ch.object);
        offset = nrPerfectTimingEstimate(pathGains, pathFilters);

    end
    rxWaveNoise = rxWaveNoise(1+offset:end, :);

    %OFDM-demoduler: bølge -> grid
    rxGrid = nrOFDMDemodulate(carrier, rxWaveNoise);

    %Kanalestimat: finn ut hva kanalen gjorde med hver rute
    if strcmpi(ch.type, 'AWGN')
        H = ones(size(rxGrid));
    else
        H = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);
    end

    %Hent symbolene (og kanalestimatet) ut fra samme ruter
    [rxSym, Hpdsch] = nrExtractResources(pdschInd, rxGrid, H);

    %Utjevning: rett opp det kanalen gjorde
    [eqSym, csi] = nrEqualizeMMSE(rxSym, Hpdsch, noiseVariance);

    %Gjør om til LLR-er, vektet med hvor pålitelig hvert symbol er
    [llrs, rxSymbols] = nrPDSCHDecode(carrier, pdsch, eqSym, noiseVariance); %LLR-ene lages
    csi = nrLayerDemap(csi); %Sorterer csi på samme måte som symbolene
    Qm = length(llrs{1}) / length(rxSymbols{1}); %Antall bits regnet ut
    csi = repmat(csi{1}.', Qm, 1); %Repmat kopierer hver csi-verdi 4 ganger
    llrs{1} = llrs{1} .* csi(:); %Hver LLR ganges med sin pålitelighet
end