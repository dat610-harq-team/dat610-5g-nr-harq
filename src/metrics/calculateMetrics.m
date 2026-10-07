function metrics = calculateMetrics(raw)
%CALCULATEMETRICS Calculate link-level metrics from HARQ transmission events.
% raw.events must be a table with one row per TB transmission and variables:
%   tbId, slot, attempt, tbsBits, crcError, terminal
% raw.numSlots and raw.slotDurationSeconds define the measurement interval.
% A terminal event is a successful decode or a TB discarded after its retry
% limit. TBs still active at the end of the run are treated as censored.

    requiredVariables = ["tbId", "slot", "attempt", "tbsBits", ...
        "crcError", "terminal"];
    if ~isfield(raw, "events") || ~istable(raw.events) || ...
            ~all(ismember(requiredVariables, string(raw.events.Properties.VariableNames)))
        error("calculateMetrics:InvalidEvents", ...
            "raw.events must be a table containing: %s.", ...
            strjoin(requiredVariables, ", "));
    end
    if ~isfield(raw, "numSlots") || ~isfield(raw, "slotDurationSeconds") || ...
            ~isscalar(raw.numSlots) || raw.numSlots <= 0 || ...
            ~isscalar(raw.slotDurationSeconds) || raw.slotDurationSeconds <= 0
        error("calculateMetrics:InvalidDuration", ...
            "raw.numSlots and raw.slotDurationSeconds must be positive scalars.");
    end

    events = raw.events;
    if isempty(events)
        error("calculateMetrics:EmptyEvents", ...
            "At least one observed transmission event is required.");
    end
    validateattributes(raw.numSlots, {'numeric'}, {'scalar','integer','positive','finite'});
    validateattributes(raw.slotDurationSeconds, {'numeric'}, {'scalar','real','positive','finite'});
    validateattributes(events.tbId, {'numeric'}, {'column','integer','positive','finite'});
    validateattributes(events.slot, {'numeric'}, {'column','integer','nonnegative','<',raw.numSlots});
    validateattributes(events.attempt, {'numeric'}, {'column','integer','positive','finite'});
    validateattributes(events.tbsBits, {'numeric'}, {'column','integer','positive','finite'});
    if ~all(ismember(events.crcError,[0 1])) || ~all(ismember(events.terminal,[0 1]))
        error('calculateMetrics:InvalidFlags','crcError and terminal must contain only 0 or 1.');
    end

    tbIds = unique(events.tbId, "stable");
    tbCount = numel(tbIds);
    completed = false(tbCount, 1);
    delivered = false(tbCount, 1);
    attemptCounts = zeros(tbCount, 1);
    retransmissionCounts = zeros(tbCount, 1);
    deliverySlots = NaN(tbCount, 1);
    firstSlots = NaN(tbCount, 1);
    tbSizes = zeros(tbCount, 1);

    for tbIndex = 1:tbCount
        rows = events(events.tbId == tbIds(tbIndex), :);
        rows = sortrows(rows, "attempt");
        attempts = rows.attempt;
        if ~isequal(attempts(:), (1:height(rows)).') || ...
                any(diff(rows.slot) <= 0) || ...
                any(rows.tbsBits ~= rows.tbsBits(1))
            error("calculateMetrics:InvalidTbHistory", ...
                "Each TB must have consecutive attempts, increasing slots, and a constant TBS.");
        end
        if any(~rows.crcError & ~rows.terminal)
            error('calculateMetrics:NonterminalSuccess','A successful decode must terminate the TB.');
        end
        if nnz(rows.terminal) > 1 || (any(rows.terminal) && ~rows.terminal(end))
            error("calculateMetrics:InvalidTerminalEvent", ...
                "A TB may have at most one terminal event, and it must be its final event.");
        end

        attemptCounts(tbIndex) = height(rows);
        retransmissionCounts(tbIndex) = height(rows) - 1;
        firstSlots(tbIndex) = rows.slot(1);
        tbSizes(tbIndex) = rows.tbsBits(1);
        completed(tbIndex) = rows.terminal(end);
        delivered(tbIndex) = completed(tbIndex) && ~rows.crcError(end);
        if delivered(tbIndex)
            deliverySlots(tbIndex) = rows.slot(end);
        end
    end

    firstAttempts = events.attempt == 1;
    completedCount = nnz(completed);
    deliveredCount = nnz(delivered);
    elapsedSeconds = raw.numSlots * raw.slotDurationSeconds;

    metrics.firstTransmissionBLER = mean(events.crcError(firstAttempts));
    metrics.finalResidualBLER = NaN;
    if completedCount > 0
        metrics.finalResidualBLER = nnz(completed & ~delivered) / completedCount;
    end
    metrics.deliveredTransportBlockBits = sum(tbSizes(delivered));
    metrics.goodputBitsPerSecond = metrics.deliveredTransportBlockBits / elapsedSeconds;
    metrics.retransmissionProbability = NaN;
    metrics.meanRetransmissionsPerDeliveredTb = NaN;
    if completedCount > 0
        metrics.retransmissionProbability = ...
            nnz(completed & retransmissionCounts > 0) / completedCount;
    end
    if deliveredCount > 0
        metrics.meanRetransmissionsPerDeliveredTb = ...
            mean(retransmissionCounts(delivered));
        latencySlots = deliverySlots(delivered) - firstSlots(delivered) + 1;
        metrics.meanDeliveryLatencySlots = mean(latencySlots);
        metrics.meanDeliveryLatencySeconds = ...
            metrics.meanDeliveryLatencySlots * raw.slotDurationSeconds;
    else
        metrics.meanDeliveryLatencySlots = NaN;
        metrics.meanDeliveryLatencySeconds = NaN;
    end
    metrics.observedTransportBlocks = tbCount;
    metrics.elapsedSeconds = elapsedSeconds;
    metrics.firstTransmissionErrors = nnz(events.crcError(firstAttempts));
    metrics.droppedTransportBlocks = nnz(completed & ~delivered);
    metrics.retransmittedTransportBlocks = nnz(completed & retransmissionCounts > 0);
    metrics.transmissionAttempts = height(events);
    metrics.retransmissionAttempts = nnz(events.attempt > 1);
    metrics.retransmissionResourceShare = metrics.retransmissionAttempts / height(events);
    metrics.idleSlots = raw.numSlots - numel(unique(events.slot));
    metrics.completedTransportBlocks = completedCount;
    metrics.deliveredTransportBlocks = deliveredCount;
    metrics.incompleteTransportBlocks = tbCount - completedCount;
    metrics.meanAttemptsPerDeliveredTb = NaN;
    if deliveredCount > 0
        metrics.meanAttemptsPerDeliveredTb = mean(attemptCounts(delivered));
    end
end
