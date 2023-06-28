function [success, EchoWavePath, asmcmd, status] = CheckEchoWaveConnection(varargin)
% Check the connection to Telemed Echo Wave II
% Return 0 if connection fails. 
% Return 1 if connection is successful.
% wrc 26OCT2022
sep = filesep; success = 0;
EchoWavePath  = FindTelemedEchoWavePath;
EchoWaveExeFile = [EchoWavePath sep 'EchoWave.exe'];
asm_path =  [EchoWavePath '\Config\Plugins\AutoInt1Client.dll'];
if ~exist(EchoWaveExeFile, 'file'),  report_connnection_failed; return; end
if ~exist(asm_path, 'file'),  report_connnection_failed; return; end
asm = NET.addAssembly(asm_path); %#ok<*NASGU> 
asmcmd = AutoInt1Client.CmdInt1();
status = asmcmd.ConnectToRunningProgram();
if (status ~= 0), report_connnection_failed; return; end
success = 1; 
fprintf('Successfully connected to Echo Wave!\n')
fprintf('Echo Wave:%d\n', status)
print_reminder;
     function report_connnection_failed()
        fprintf('Failed to connect to Echo Wave!\n');
        print_check_list; print_reminder;
    end  %report_connnection_failed()
    function print_check_list()
        fprintf('Check list: \n'); fprintf('- MATLAB and Echo Wave must be run as administrator\n');
        fprintf('- Must run AutoInt1_regasm.bat  (only once for each PC)  in CMD as administrator.\n');
        fprintf('(Open Windows CMD as administrator; Browse to EchoWave Plugin folder; Type "AutoInt1_regasm.bat")\n');
    end % print_check_list()
    function print_reminder()
        fprintf('\n'); fprintf('Reminder:\n'); fprintf('In Echo Wave....\n');
        fprintf('Menu -> Tools -> Options \n'); fprintf('Scanning Control:General: \n');
        fprintf('Automatic freeze: Uncheck (disable) "Enable Auto Freeze"\n');
        fprintf('Other: Uncheck "Freeze ultrasound image when software is minimized"\n');
        fprintf('Other: Uncheck "Use right mouse button for freeze/unfreeze" to avoid accidental interruption.\n');
        fprintf('{default} Check Actions on Startup:"Disable Windows screen saver"\n');
        fprintf('{default} Check Actions on Startup:"Disable Windows power saver"\n');  fprintf('\n');
        fprintf('Scanning Control:Cine: \n'); fprintf('- Increase Cine size to at least 2GB (the more the better). \n'); 
        fprintf('- Uncheck "Automatically play opened TVD file"\n'); fprintf('\n');
    end %print_reminder()
end %CheckEchoWaveConnection
%% 

%%
function EchoWavePath  = FindTelemedEchoWavePath(varargin)
% Find the path of installed Echo Wave II in Windows. 
% Return empty if not found.
% wrc 26OCT2022
sep = filesep;
programFilesFolders = {'Program Files', 'Program Files (x86)'};
EchoWaveFolder = 'Telemed\Echo Wave II';
exeFN = 'EchoWave.exe';
startDrive = 'C'; endDrive = 'Z';
found = 0; EchoWavePath = [];
for i = double(startDrive):double(endDrive)
    drive = [char(i), ':' sep]; 
    for j = 1:numel(programFilesFolders)
        programFilesFolder = programFilesFolders{j};
        pathCandidate = [drive, programFilesFolder, sep, EchoWaveFolder];
        candEchoWaveExeFN = fullfile(pathCandidate, exeFN);
        if exist(candEchoWaveExeFN, 'file'), 
            found = 1; EchoWavePath = pathCandidate; return; %#ok<*NASGU> 
        end
    end
end
% if ~found, fprintf('Telemed EchoWave NOT found!\n'); end
end % FindTelemedEchoWavePath()
