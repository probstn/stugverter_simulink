%% stugverter.m
% =========================================================================
% STUGVERTER MOTOR CONTROL WORKFLOW
% =========================================================================
% Paths are managed by stugverter.prj.
% In the MATLAB Editor, place your cursor in any section and press Ctrl+Enter
% to execute that specific task.

%% 1. Simulate (open scopes with results)
run('run_simulation.m');

%% 2. Generate Code
run('generate_code.m');

%% 3. Deploy Algorithm
run('deploy_code.m');

%% 4. Flash Target MCU (winIDEA)
run('flash_target.m');

%% 5. HIL Test (switch simulink model + stugverter into HIL mode and test)
run('run_hil.m');

%% 6. Validate SIL/HIL Equivalence (runs both modes and asserts tolerances)
run('validate_sil_hil.m');
