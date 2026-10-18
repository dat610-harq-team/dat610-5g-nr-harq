clear;
ensureHarqReference();
cfg = defaultConfig();
cfg.NumTransportBlocks = 1000;

scenario.SNRdB = 7;
scenario.Seed = 610;
scenario.RVSequence = [0 2 3 1];

% Uten Channel-felt: gammel symbol-AWGN
resultOld = runHarqLinkSimulation(cfg, scenario);
disp('Symbol-AWGN:'); disp(resultOld.metrics)

% Med Channel-felt: din bølge-vei med TDL-C
scenario.Channel.channelType = 'AWGN';
scenario.Channel.DelaySpread = 300e-9;
scenario.Channel.MaximumDopplerShift = 5;
resultTDL = runHarqLinkSimulation(cfg, scenario);
disp('Bølge-vei TDL-C:'); disp(resultTDL.metrics)