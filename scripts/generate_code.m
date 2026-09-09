%% generate_code.m
% =========================================================================
% CODE GENERATION SCRIPT FOR ALGORITHM
% =========================================================================
% Triggers Embedded Coder build for algorithm.slx and verifies the
% generated C code artifacts in algorithm_ert_rtw.

fprintf('\n================================================================\n');
fprintf(' [CODEGEN] Generating C Code from algorithm.slx...\n');
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

origPwd = pwd;
cd(simulinkDir);
cleanupObj = onCleanup(@() cd(origPwd));

scriptsDir = fullfile(simulinkDir, 'scripts');
modelsDir  = fullfile(simulinkDir, 'models');
if isfolder(scriptsDir), addpath(scriptsDir); end
if isfolder(modelsDir),  addpath(modelsDir);  end

% Ensure workspace variables are available
if ~exist('foc', 'var') || ~exist('pmsm', 'var')
    run(fullfile(simulinkDir, 'scripts', 'init.m'));
end

algoModel = 'algorithm';
if ~bdIsLoaded(algoModel)
    load_system(algoModel);
end

fprintf('Running Embedded Coder slbuild("%s")...\n', algoModel);
tic;
slbuild(algoModel);
buildElapsed = toc;
fprintf('Code generation finished in %.2f s.\n', buildElapsed);

codegenDir = fullfile(simulinkDir, [algoModel, '_ert_rtw']);
if ~exist(codegenDir, 'dir')
    error('Expected code generation directory not found: %s', codegenDir);
end

cFiles = dir(fullfile(codegenDir, '*.c'));
hFiles = dir(fullfile(codegenDir, '*.h'));
fprintf('\nGenerated %d source and %d header file(s) in %s:\n', ...
    length(cFiles), length(hFiles), codegenDir);
for k = 1:length(cFiles)
    fprintf('  - %s\n', cFiles(k).name);
end
for k = 1:length(hFiles)
    fprintf('  - %s\n', hFiles(k).name);
end
fprintf('================================================================\n');
fprintf(' Code generation completed successfully.\n');
fprintf('================================================================\n\n');
