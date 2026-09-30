function state = updateHarqState(state, feedback)
%UPDATEHARQSTATE Placeholder for one HARQ state transition.
% Owner: Person 2.
% Inputs: state - current HARQ state; feedback - future decoder feedback.
% Output: state - eventually, the updated HARQ state.
%
% Investigate in the MathWorks HARQ/PDSCH example:
%   - Where does ACK/NACK arrive?
%   - Which HARQ process is updated?
%   - What changes after a failed decode?
%   - What happens before a retransmission?
%   - Which feedback fields are actually needed here?

    state = struct(); % Placeholder only; no transition is performed.
end
