function TelemedConvertVideoFormat(filePath, fromFormat, toFormat)
persistent EchoWavePath
if nargin < 3 || isempty(toFormat), toFormat = 'avi_wmv9';end
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
% wrc 26OCT2022
sep = filesep;
programFilesFolders = {'Program Files', 'Program Files (x86)'};
EchoWaveFolder = 'Telemed\Echo Wave II';
startDrive = 'C'; endDrive = 'Z';
found = 0; EchoWavePath = [];
for i = double(startDrive):double(endDrive)
    drive = [char(i), ':' sep]; 
    for j = 1:numel(programFilesFolders)
        programFilesFolder = programFilesFolders{j};
        pathCandidate = [drive, programFilesFolder, sep, EchoWaveFolder];
        if exist(pathCandidate, 'dir') == 7
            found = 1; EchoWavePath = pathCandidate; return; %#ok<*NASGU> 
        end
    end
end
if ~found, fprintf('Telemed EchoWave NOT found!\n'); end
end % FindTelemedEchoWavePath