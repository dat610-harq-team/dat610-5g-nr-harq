function raw = recordHarqEvent(raw, event)
%RECORDHARQEVENT Placeholder for HARQ counter instrumentation.
% Owner: Person 2.
% Inputs: raw - future counters; event - a future, agreed HARQ event.
% Output: raw - eventually, counters updated for that event.
%
% Investigate:
%   - At what point is an initial transmission counted?
%   - Which event counts as a retransmission or final failure?
%   - What must be recorded to distinguish attempts from deliveries?
%   - Which event fields should be agreed with runSimulation?

    raw = struct(); % Placeholder only; no event is recorded.
end
