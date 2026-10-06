%% Experiment 1 - SNR
% Owner: Person 1
%
% First working smoke test for the shared simulation.
% The SNR values below are NOT the final scientifically justified sweep.
% They simply check that the baseline responds sensibly to changing SNR.

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot,"src")));

cfg = defaultConfig();

snrValues = [2 7 12];

results = repmat(struct(),1,numel(snrValues));

fprintf("\n5G NR HARQ baseline smoke test\n");
fprintf("---------------------------------------------\n");

for idx = 1:numel(snrValues)

    scenario.SNRdB = snrValues(idx);
    results(idx) = runSimulation(cfg,scenario);

    raw = results(idx).raw;

    fprintf("SNR = %g dB\n",scenario.SNRdB);
    fprintf("  transport blocks      : %d\n",raw.totalTransportBlocks);
    fprintf("  transmission attempts : %d\n",raw.totalTransmissionAttempts);
    fprintf("  retransmissions       : %d\n",raw.totalRetransmissions);
    fprintf("  final failed blocks   : %d\n\n",raw.finalFailedTransportBlocks);
end

% Next:
% - inspect whether lower SNR causes more retransmissions/failures
% - agree with Person 2 on exact metric definitions
% - justify the final SNR range
% - only then add final plots and larger runs
