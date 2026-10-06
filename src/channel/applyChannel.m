function receivedWaveform = applyChannel(channel, transmittedWaveform)
%APPLYCHANNEL Placeholder between NR transmission and reception.
% Owner: Person 3.
% Inputs: channel - validated channel setup;
%         transmittedWaveform - waveform produced by the NR transmitter.
% Output: receivedWaveform - eventually, the waveform after the channel.
%
% Investigate:
%   - Where does the reference apply fading and noise?
%   - How are sample rate, delay, timing, and SNR handled?
%   - What differs between AWGN and one validated TDL case?

if strcmpi(channel.type, 'AWGN')
    receivedWaveform = transmittedWaveform;

elseif startsWith(channel.type, 'TDL', 'IgnoreCase', true)
    chInfo = info(channel.object);
    maxChDelay = ceil(max(chInfo.PathDelays*channel.object.SampleRate)) + chInfo.ChannelFilterDelay;

    paddedWaveform = [transmittedWaveform; zeros(maxChDelay, size(transmittedWaveform,2))];
    receivedWaveform = channel.object(paddedWaveform);
else
    error("Unknown channel type. Use 'AWGN' or a TDL profile");

end
end
