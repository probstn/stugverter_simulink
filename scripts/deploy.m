%% deploy.m
% Deploys generated C/C++ algorithm source and header files to the AURIX project firmware

% Resolve paths relative to this script
scriptDir = fileparts(mfilename('fullpath'));
simulinkRoot = fullfile(scriptDir, '..');

% Default controller model name if not already defined
if ~exist('controllerModel', 'var') || isempty(controllerModel)
    controllerModel = 'algorithm';
end

codegenDir = fullfile(simulinkRoot, [controllerModel, '_ert_rtw']);
firmwareAlgorithmDir = fullfile(simulinkRoot, '..', 'firmware', 'algorithm');

disp(['Deploying generated code for "', controllerModel, '" to AURIX project...']);

% Check if codegen directory exists
if ~exist(codegenDir, 'dir')
    error(['Code generation directory not found: ', codegenDir, '. Please build the model first.']);
end

% Ensure destination folder exists
if ~exist(firmwareAlgorithmDir, 'dir')
    mkdir(firmwareAlgorithmDir);
end

% Get all .c and .h files in the code generation directory
cFiles = dir(fullfile(codegenDir, '*.c'));
hFiles = dir(fullfile(codegenDir, '*.h'));
allFiles = [cFiles; hFiles];

% Filter to only necessary algorithm files (exclude standalone test harness ert_main.c)
excludeList = {'ert_main.c'};

deployedCount = 0;
for k = 1:length(allFiles)
    fileName = allFiles(k).name;
    if any(strcmp(fileName, excludeList))
        continue;
    end
    
    srcFile = fullfile(codegenDir, fileName);
    destFile = fullfile(firmwareAlgorithmDir, fileName);
    copyfile(srcFile, destFile);
    disp(['  Deployed: ', fileName]);
    deployedCount = deployedCount + 1;
end

if deployedCount == 0
    warning(['No algorithm files were deployed from: ', codegenDir]);
else
    disp(['Successfully deployed ', num2str(deployedCount), ' algorithm file(s) to: ', firmwareAlgorithmDir]);
end
