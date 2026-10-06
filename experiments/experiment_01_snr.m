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

% Store each simulation result in a cell because runSimulation returns a
% structure with fields.
results = cell(1,numel(snrValues));

fprintf("\n5G NR HARQ baseline smoke test\n");
fprintf("------------------------------------------------------------\n");

for idx = 1:numel(snrValues)

    scenario.SNRdB = snrValues(idx);
    results{idx} = runSimulation(cfg,scenario);

    raw = results{idx}.raw;

    % Simple descriptive values for the smoke test.
    % Person 2 will later help confirm the final metric definitions used
    % in the report and in calculateMetrics.m.
    firstAttemptFailures = sum(raw.firstAttemptBlockError);
    firstAttemptBLER = firstAttemptFailures / raw.totalTransportBlocks;

    averageRetransmissionsPerBlock = ...
        raw.totalRetransmissions / raw.totalTransportBlocks;

    averageTransmissionAttempts = ...
        raw.totalTransmissionAttempts / raw.totalTransportBlocks;

    finalFailureRate = ...
        raw.finalFailedTransportBlocks / raw.totalTransportBlocks;

    fprintf("SNR = %g dB\n",scenario.SNRdB);
    fprintf("  transport blocks                  : %d\n",raw.totalTransportBlocks);
    fprintf("  first-attempt failures            : %d\n",firstAttemptFailures);
    fprintf("  first-attempt BLER                : %.3f (%.1f%%)\n", ...
        firstAttemptBLER,firstAttemptBLER*100);
    fprintf("  total transmission attempts       : %d\n",raw.totalTransmissionAttempts);
    fprintf("  total retransmissions             : %d\n",raw.totalRetransmissions);
    fprintf("  average retransmissions per block : %.2f\n", ...
        averageRetransmissionsPerBlock);
    fprintf("  average transmission attempts     : %.2f\n", ...
        averageTransmissionAttempts);
    fprintf("  final failed blocks               : %d\n",raw.finalFailedTransportBlocks);
    fprintf("  final failure rate                : %.3f (%.1f%%)\n\n", ...
        finalFailureRate,finalFailureRate*100);
end

% Next:
% - inspect how much HARQ recovers between first-attempt and final failure
% - agree with Person 2 on exact metric definitions
% - justify the final SNR range
% - only then add final plots and larger runs
