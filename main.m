%% main.m
% =========================================================================
% STUGVERTER MOTOR CONTROL WORKFLOW
% =========================================================================
% Paths are managed by stugverter.prj.  Entry models are deliberately
% separate so saved HIL transport settings cannot affect SIL.
% In the MATLAB Editor, place your cursor in any section and press Ctrl+Enter
% to execute that specific task.

simulinkDir = fileparts(mfilename('fullpath'));
addpath(fullfile(simulinkDir, 'scripts'), fullfile(simulinkDir, 'models'));

%% 1. Simulate (open scopes with results)
run(fullfile(simulinkDir, 'scripts', 'run_simulation.m'));

%% 2. Generate Code
run(fullfile(simulinkDir, 'scripts', 'generate_code.m'));

%% 3. Deploy Algorithm
run(fullfile(simulinkDir, 'scripts', 'deploy_code.m'));

%% 4. Flash Target MCU (winIDEA)
run(fullfile(simulinkDir, 'scripts', 'flash_target.m'));

%% 5. HIL Test (stugverter_hil: simulated plant + TC387 algorithm)
run(fullfile(simulinkDir, 'scripts', 'run_hil.m'));

%% 6. Validate SIL/HIL Equivalence (runs both modes and asserts tolerances)
run(fullfile(simulinkDir, 'scripts', 'validate_sil_hil.m'));

%% 7. Actual Hardware Monitor (read-only XCP DAQ; no simulated plant/STIM)
run(fullfile(simulinkDir, 'scripts', 'run_hardware.m'));
