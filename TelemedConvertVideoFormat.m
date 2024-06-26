function TelemedConvertVideoFormat(filePath, fromFormat, toFormat)
% WR Chen 26OCT2022
%     Update:  02JUN2023  
% toFormat: video output formats: avi_comp, avi, avi_cust, avi_wmv9, mp4, dcm_jpeg_cine, dcm_cine
persistent EchoWavePath
if nargin < 3 || isempty(toFormat), toFormat = 'mp4';end
if nargin < 2 || isempty(fromFormat), fromFormat = 'tvd'; end
if nargin < 1 || isempty(filePath), filePath = pwd;end
if isempty(EchoWavePath), EchoWavePath =  FindTelemedEchoWavePath; end
if isempty(EchoWavePath), return;end
EchoWaveCmd = sprintf('"%s\\EchoWave.exe"', EchoWavePath);
outPath = ['"' filePath '"'];
convertFmtCmd = [EchoWaveCmd ' -convert_directory ' outPath ' ' fromFormat ' ' toFormat]; 
[status,cmdout] = system(convertFmtCmd, '-echo'); %#ok<*ASGLU> 
end %TelemedConvertVideoFormat
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
            if exist(candEchoWaveExeFN, 'file'), 
                found = 1; EchoWavePath = pathCandidate; return; %#ok<*NASGU> 
            end
        end
    end
end
% if ~found, fprintf('Telemed EchoWave NOT found!\n'); end
end % FindTelemedEchoWavePath()