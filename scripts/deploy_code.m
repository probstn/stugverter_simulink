%% deploy_code.m
% =========================================================================
% DEPLOY GENERATED ALGORITHM CODE TO FIRMWARE
% =========================================================================
% Copies generated C source and header files from algorithm_ert_rtw to
% firmware/algorithm/ (excluding standalone wrapper ert_main.c).

fprintf('\n================================================================\n');
fprintf(' [DEPLOY] Deploying Generated Code to firmware/algorithm/...\n');
fprintf('================================================================\n');

if exist('resolve_simulink_dir', 'file') == 2
    simulinkDir = resolve_simulink_dir();
else
    try
        proj = currentProject;
        simulinkDir = proj.RootFolder;
    catch
        candidates = {pwd, fullfile(pwd, 'simulink'), fileparts(pwd), ...
                      fullfile(fileparts(pwd), 'simulink'), ...
                      'C:\Users\probst\Desktop\stugverter\simulink'};
        simulinkDir = pwd;
        for k = 1:length(candidates)
            if exist(fullfile(candidates{k}, 'scripts', 'init.m'), 'file')
                simulinkDir = candidates{k};
                break;
            end
        end
    end
end

projectRoot = fileparts(simulinkDir);
codegenDir = fullfile(simulinkDir, 'algorithm_ert_rtw');
firmwareAlgoDir = fullfile(projectRoot, 'firmware', 'algorithm');

if ~exist(codegenDir, 'dir')
    error('Code generation directory "%s" not found. Please run generate_code.m first.', codegenDir);
end

if ~exist(firmwareAlgoDir, 'dir')
    fprintf('Creating target directory: %s\n', firmwareAlgoDir);
    mkdir(firmwareAlgoDir);
end

allSourceFiles = [dir(fullfile(codegenDir, '*.c')); dir(fullfile(codegenDir, '*.h'))];
excludeList = {'ert_main.c', 'ert_main.h'};

deployedCount = 0;
for k = 1:length(allSourceFiles)
    fileName = allSourceFiles(k).name;
    if any(strcmp(fileName, excludeList))
        continue;
    end
    
    srcPath  = fullfile(codegenDir, fileName);
    destPath = fullfile(firmwareAlgoDir, fileName);
    copyfile(srcPath, destPath);
    fprintf('  Deployed -> %s\n', fileName);
    deployedCount = deployedCount + 1;
end

fprintf('\nSuccessfully deployed %d file(s) to:\n  %s\n', deployedCount, firmwareAlgoDir);
fprintf('================================================================\n');
fprintf(' Deployment complete! Target is ready to compile and flash.\n');
fprintf('================================================================\n\n');
