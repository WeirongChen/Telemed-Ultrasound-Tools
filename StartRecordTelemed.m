function StartRecordTelemed(dur, saveFileName, fmt, ifAudio)
% 1 second = 1.4MB (including vidoe & audio)
% 1 minute = 84MB
% 1 hour = ~5GB
% WR Chen 19DEC2022
persistent asmcmd
persistent EchoWavePath
if nargin < 4 || isempty(ifAudio), ifAudio = 1; end
if nargin < 3 || isempty(fmt), fmt = 'tvd'; end
% if nargin < 3 || isempty(fmt), fmt = 'mp4'; end
sep = filesep; fExt = ['.' fmt]; 
if nargin < 1 || isempty(dur), dur = 300; end
if nargin < 2 || isempty(saveFileName), saveFileName = [pwd sep 'test']; end
if isempty(EchoWavePath), EchoWavePath =  FindTelemedEchoWavePath; end
[p, f, e]= fileparts(saveFileName); 
if isempty(p), p = pwd; end
if isempty(e), e = fExt; end
saveFileName = [p sep f, e]; 

EchoWaveCmd = sprintf('"%s\\EchoWave.exe"', EchoWavePath);
% outFileName = ['"' saveFileName '"'];
% saveCineCmd = [EchoWaveCmd ' -save_cine ' fmt ' ' outFileName]; % must specify absolute path.

if isempty(asmcmd)
     asm_path =  [EchoWavePath '\Config\Plugins\AutoInt1Client.dll'];
     asm = NET.addAssembly(asm_path); %#ok<*NASGU> 
     asmcmd = AutoInt1Client.CmdInt1();
end
status = asmcmd.ConnectToRunningProgram();
if (status ~= 0), fprintf('Error in Echo Wave II software.\n'); return; end

nDispSteps = 100; % Display progress in 20 steps.
dispPeriod = dur / nDispSteps; 
if ifAudio
    audioExt = '.wav'; audio_dev_idx = 0;  audio_srate = 22050;  num_audio_channels = 2; bit_rate = 16; 
    [p, f, ~] = fileparts(saveFileName); audioFileName = [p, sep, f, audioExt];
	devs = audiodevinfo;
	k = find(cell2mat({devs.input.ID}) == audio_dev_idx, 1);
	if isempty(k), error('audio input device %d not available', audio_dev_idx), end
    recObj= audiorecorder(audio_srate, bit_rate, num_audio_channels, audio_dev_idx);
    set(recObj, 'timerFcn', @DispProgress, 'TimerPeriod', dispPeriod, ...
      'Tag', 'ultrasound_audio');
    fprintf('Start recording.\n ');
    record(recObj);
    EchoWaveStartRecord(asmcmd);
    pause(dur);
    fprintf('\nStop recording.\n ');
      [nFrames, duration, frameWidth, frameHeight, recordEndTimeStr]=EchoWaveStopRecordAndSave(asmcmd, EchoWavePath,  saveFileName);
    stop(recObj);
    s = getaudiodata(recObj);
	audiowrite(audioFileName,s , audio_srate);
else
    fprintf('Start recording.\n ');
    EchoWaveStartRecord(asmcmd)
    pause(dur);
    fprintf('\nStop recording.\n ');
    [nFrames, duration, frameWidth, frameHeight, recordEndTimeStr]=EchoWaveStopRecordAndSave(asmcmd, EchoWavePath,  saveFileName);
end
    function DispProgress(recObj, event)
        fprintf('.');
    end
end %StartRecordTelemed

%%
% id_scanning_state_set = 201;
% id_scanning_state_get = 200;
% id_state_b_b1r = 1; % B-mode scan running
%  id_state_b_b1f = 2;  % B-mode frozen
% asmcmd.ParamGetInt(id_scanning_state_get)
% asmcmd.ParamSet(id_scanning_state_set, id_state_b_b1r)
% asmcmd.ParamSet(id_scanning_state_set, id_state_b_b1f)

%%
function EchoWaveStartRecord(asmcmd)
id_scanning_state_set = 201;
id_scanning_state_get = 200;
id_state_b_b1r = 1; % B-mode scan running
id_state_b_b1f = 2;  % B-mode frozen
    status = asmcmd.ConnectToRunningProgram();
    if (status ~= 0), fprintf('Error in Echo Wave II software.\n'); return; end
    % stop recording
    if (asmcmd.IsRecordingState() == 1), asmcmd.RecordStop(); end
    % freeze ultrasound scanning
    if (asmcmd.IsRunState() == 1), asmcmd.FreezeRun(); end
    % pause cine playback
    if (asmcmd.IsPlayState() == 1), asmcmd.PlayPause(); end
    %Start recording:
   asmcmd.ParamSet(id_scanning_state_set, id_state_b_b1r); % B-mode scan running
end %EchoWaveStartRecord(asmcmd)
%% 
function [nFrames, duration, frameWidth, frameHeight, recordEndTimeStr]=EchoWaveStopRecordAndSave(asmcmd, EchoWavePath, fName)
id_scanning_state_set = 201;
id_scanning_state_get = 200;
id_state_b_b1r = 1; % B-mode scan running
id_state_b_b1f = 2;  % B-mode frozen
id_get_cine_end_date_time_str	= 690; %Get cine end (freeze) absolute date and time as string. Format: "yyyy.MM.dd HH:mm:ss.ffffff"
sep = filesep; tvdExt = '.tvd';  [p, f, e]= fileparts(fName); 
if isempty(p), p = pwd; end
saveFileName = [p, sep, f]; logFilename = [p sep 'Telemed.log'];
saveFileName = ['"' saveFileName tvdExt '"']; 
EchoWaveCmd = sprintf('"%s\\EchoWave.exe"', EchoWavePath);
saveCineCmd = [EchoWaveCmd ' -save_cine tvd ' saveFileName]; % must specify absolute path for the output  file.
% stop recording
if (asmcmd.IsRecordingState() == 1), asmcmd.RecordStop(); end
% freeze ultrasound scanning
% if (asmcmd.IsRunState() == 1), asmcmd.FreezeRun(); end % Freeze
asmcmd.ParamSet(id_scanning_state_set, id_state_b_b1f);  % Freeze
% pause cine playback
if (asmcmd.IsPlayState() == 1), asmcmd.PlayPause(); end
% save TVD file
[status,cmdout] = system(saveCineCmd, '-echo');  % It roughly takes 1 s to save 5 s video; takes 5 s to save 5 min video.
% tic
nFrames = asmcmd.GetFramesCount();
duration = asmcmd.GetCurrentFrameTime();
frameWidth = asmcmd.GetLoadedFrameWidth();
frameHeight = asmcmd.GetLoadedFrameHeight();
recordEndTimeStr = asmcmd.ParamGetString(id_get_cine_end_date_time_str);
try
    fid = fopen(logFilename, 'at'); % append log file
    fprintf(fid,'%s: %d frames; %0.3f ms; Width: %d; Height: %d\n', ...
        recordEndTimeStr, ...
        nFrames, duration, frameWidth, frameHeight);
    fclose(fid);
catch
end
% toc
end %EchoWaveStopRecordAndSave()
%%
function EchoWavePath  = FindTelemedEchoWavePath(varargin)
% Find the path of installed Echo Wave II in Windows. 
% Return empty if not found.
% WR Chen 26OCT2022
%     Update:  02JUN2023  
%              Starting from EchoWave 4.2.0, the application
%              folder changed to Program Files\Telemed\Echo Wave II Application\.
%              If both older and newer version of EchoWave applications
%              exist, this script will return the newer version.
sep = filesep;
programFilesFolders = {'Program Files', 'Program Files (x86)'};
EchoWaveFolders = {'Telemed\Echo Wave II Application\EchoWave II', 'Telemed\Echo Wave II'}; nEchoWaveFolders = numel(EchoWaveFolders);
exeFN = 'EchoWave.exe';
startDrive = 'C'; endDrive = 'Z';
found = 0; EchoWavePath = [];
for i = double(startDrive):double(endDrive)
    drive = [char(i), ':' sep]; 
    for j = 1:numel(programFilesFolders)
        programFilesFolder = programFilesFolders{j};
        for k = 1:nEchoWaveFolders            
            EchoWaveFolder = EchoWaveFolders{k};
            pathCandidate = [drive, programFilesFolder, sep, EchoWaveFolder];
            candEchoWaveExeFN = fullfile(pathCandidate, exeFN);
            if exist(candEchoWaveExeFN, 'file')
                found = 1; EchoWavePath = pathCandidate; return; %#ok<*NASGU> 
            end
        end
    end
end
% if ~found, fprintf('Telemed EchoWave NOT found!\n'); end
end % FindTelemedEchoWavePath()
%%
% freezeCmd = [EchoWaveCmd ' -freeze'];
% clearCineCmd = [EchoWaveCmd ' -clear_cine'];
% runCmd = [EchoWaveCmd ' -run'];

% [status,cmdout] = system(freezeCmd, '-echo');
% [status,cmdout] = system(freezeCmd, '-echo');
% [status,cmdout] = system(clearCineCmd, '-echo');
% [status,cmdout] = system(runCmd, '-echo');
