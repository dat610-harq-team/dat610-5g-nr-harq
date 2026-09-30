function metrics = calculateMetrics(raw)
%CALCULATEMETRICS Placeholder for metrics derived from raw counters.
% Owner: Person 2; agree on definitions with the whole group.
% Input: raw - counters from a validated simulation run.
% Output: metrics - eventually, defined performance measures.
%
% Candidate measures: BLER, throughput, retransmission rate, average
% transmission attempts, and delivery time if precisely defined.
%
% Investigate before choosing counters or equations:
%   - When is a block failed with HARQ enabled?
%   - Which bits belong in the throughput numerator, and over what time?
%   - Does a retransmission count exclude the initial transmission?
%   - What would latency mean in this link-level simulation?
%   - Which quantities can the reference actually expose?

    metrics = struct(); % Placeholder only; no metric is calculated.
end
