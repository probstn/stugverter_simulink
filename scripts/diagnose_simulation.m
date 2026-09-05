% diagnose_simulation.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

fprintf('=== Running Simulation of foc_system ===\n');
load_system('foc_system');

% Check what the input speed source is in foc_system: is it Step1 or sp_ts?
step_blk = 'foc_system/Step1';
fprintf('Step1 block params: Time=%s, Before=%s, After=%s\n', ...
    get_param(step_blk, 'Time'), get_param(step_blk, 'Before'), get_param(step_blk, 'After'));

% Let's test running for 0.3 seconds to see if it reaches 18000 rpm (or whatever reference is set)
set_param('foc_system', 'StopTime', '0.3');
out = sim('foc_system');
fprintf('Simulation complete. Analyzing logged signals...\n');

% Check what variables are in out
vars = out.who;
disp('Workspace outputs:');
disp(vars);
