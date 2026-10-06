function channel = createChannel(cfg)
%CREATECHANNEL Placeholder for channel-model setup.
% Owner: Person 3.
% Input: cfg - future, agreed channel configuration.
% Output: channel - eventually, a configured channel representation.
%
% Investigate in the MATLAB reference example:
%   - How is the reference channel configured and applied?
%   - What is needed for an AWGN baseline?
%   - Which single TDL model is appropriate and why?
%   - Which parameters need scientific justification?
%   - How could Doppler/mobility enter later, if scope permits?
if strcmpi(cfg.channelType, 'AWGN')
    channel.type = cfg.channelType;
    channel.object = [];
        
elseif startsWith(cfg.channelType, 'TDL', 'IgnoreCase', true)
    tdl = nrTDLChannel;
    tdl.NumTransmitAntennas = cfg.NTxAnts;
    tdl.NumReceiveAntennas = cfg.NRxAnts;

    tdl.DelayProfile = cfg.channelType;
    tdl.DelaySpread = cfg.DelaySpread;
    tdl.MaximumDopplerShift = cfg.MaximumDopplerShift;
    tdl.SampleRate = cfg.SampleRate;
    channel.type = cfg.channelType;
    channel.object = tdl;

else
    error("Unknown channel type. Use 'AWGN' or a TDL profile");

end
end
