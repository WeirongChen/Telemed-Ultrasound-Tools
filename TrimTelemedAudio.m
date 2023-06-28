function [s, sr, locs, frameStart] = TrimTelemedAudio(FName, resampleRate)
% Trim the begining of Telemed two-channel audio, using the sync-pulse
% signals. 
% WR Chen 19DEC2022
if nargin < 2, resampleRate = [];end
[locs, audio, syncs, sr] = ParseTelemedSyncPulse(FName);
frameStart = mean(locs(1:2)); % Get the midpoint between the time of starting scanning and the completion of scanning first frame.
frameStartN = floor(frameStart * sr)+1;
s = audio(frameStartN:end);
if ~isempty(resampleRate),  s = resample(s,resampleRate,sr); sr = resampleRate; end
end %TrimTelemedAudio

function [locs, audio, syncs, sr] = ParseTelemedSyncPulse(FName, sync_channel, ifplot)
if nargin < 2, sync_channel = 2;end
if nargin < 3, ifplot = 0;end
if sync_channel == 2, audio_channel = 1; else, audio_channel = 2; end
[s, sr]= audioread(FName); nChannels = size(s,2);
for i = 1:nChannels, s1 = s(:,i); s(:,i) = s1 ./ max(abs(s1)); end
audio = s(:,audio_channel); syncs = s(:,sync_channel); 
nSamples = length(audio);
dur = (nSamples-1) / sr; 
syncs = syncs ./ max(abs(syncs)); 
min_fps = 20; max_fps = 300;
[pks, locs] = findpeaks(syncs,sr, 'MinPeakHeight', 0.3, 'MinPeakDistance',1/max_fps);
intervals = diff(locs);
%% PLOT:
if ~ifplot, return;end
close all; H = figure; hold on;
t = linspace(0, dur, nSamples);
plot(t, syncs);plot(locs, pks, 'o');

end % main;
