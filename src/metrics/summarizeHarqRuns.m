function summary = summarizeHarqRuns(perRun)
%SUMMARIZEHARQRUNS Pool counts across seeds; never average ratios blindly.
% Wilson intervals apply to independent TB outcomes in this AWGN experiment.
    labels = unique(perRun.configuration,'stable');
    rows = {};
    for label = labels.'
        snrs = unique(perRun.snrDb(perRun.configuration==label));
        for snr = snrs.'
            r = perRun(perRun.configuration==label & perRun.snrDb==snr,:);
            n = sum(r.observedTransportBlocks);
            d = sum(r.deliveredTransportBlocks);
            f = sum(r.droppedTransportBlocks);
            firstErrors = sum(r.firstTransmissionErrors);
            [firstLow,firstHigh] = wilson(firstErrors,n);
            [finalLow,finalHigh] = wilson(f,n);
            deliveredRuns = r.deliveredTransportBlocks>0;
            retxSum = sum(r.meanRetransmissionsPerDeliveredTb(deliveredRuns).*r.deliveredTransportBlocks(deliveredRuns));
            latencySum = sum(r.meanDeliveryLatencySlots(deliveredRuns).*r.deliveredTransportBlocks(deliveredRuns));
            meanRetx = NaN; meanSlots = NaN;
            if d>0, meanRetx = retxSum/d; meanSlots = latencySum/d; end
            % Conservative two-sided Hoeffding CI for independent delivered
            % block retry counts bounded by [0, maxAttempts-1].
            retxLow = NaN; retxHigh = NaN;
            if d>0 && ismember('maxAttempts',r.Properties.VariableNames)
                assert(all(r.maxAttempts==r.maxAttempts(1)), ...
                    'HARQ:MixedBudgets','Each summary group needs one attempt budget.');
                bound = r.maxAttempts(1)-1;
                halfWidth = bound*sqrt(log(40)/(2*d));
                retxLow = max(0,meanRetx-halfWidth);
                retxHigh = min(bound,meanRetx+halfWidth);
            end
            row = struct('configuration',label,'snrDb',snr,'numSeeds',height(r), ...
                'transportBlocks',n,'deliveredTransportBlocks',d,'droppedTransportBlocks',f, ...
                'firstTransmissionBLER',firstErrors/n,'firstBLERLow95',firstLow,'firstBLERHigh95',firstHigh, ...
                'finalResidualBLER',f/n,'finalBLERLow95',finalLow,'finalBLERHigh95',finalHigh, ...
                'goodputMbps',sum(r.deliveredTransportBlockBits)/sum(r.elapsedSeconds)/1e6, ...
                'meanRetransmissionsPerDeliveredTb',meanRetx,'meanAttemptsPerDeliveredTb',meanRetx+1, ...
                'meanRetxLow95',retxLow,'meanRetxHigh95',retxHigh, ...
                'meanDeliveryLatencySlots',meanSlots, ...
                'retransmissionProbability',sum(r.retransmittedTransportBlocks)/n, ...
                'retransmissionResourceShare',sum(r.retransmissionAttempts)/sum(r.transmissionAttempts));
            rows{end+1,1} = struct2table(row); %#ok<AGROW>
        end
    end
    summary = vertcat(rows{:});
end

function [low,high] = wilson(k,n)
    z = 1.95996398454005;
    p = k/n;
    center = (p+z^2/(2*n))/(1+z^2/n);
    half = z*sqrt(p*(1-p)/n+z^2/(4*n^2))/(1+z^2/n);
    low = max(0,center-half);
    high = min(1,center+half);
end
