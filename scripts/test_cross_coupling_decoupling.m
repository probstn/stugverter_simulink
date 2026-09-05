% test_cross_coupling_decoupling.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

% Let's test a current controller with clean parameters and check current loop stability
load_system('foc_controller');
load_system('foc_plant');
load_system('foc_speedcontroller');
load_system('foc_system');

% Check the Unit Delay block in foc_system
delay_blk = 'foc_system/Unit Delay';
fprintf('Unit Delay SampleTime: %s\n', get_param(delay_blk, 'SampleTime'));

% Check solver settings of foc_system and referenced models
fprintf('foc_system Solver: %s, FixedStep: %s, MaxStep: %s\n', ...
    get_param('foc_system', 'Solver'), get_param('foc_system', 'FixedStep'), get_param('foc_system', 'MaxStep'));
fprintf('foc_plant Solver: %s, FixedStep: %s, MaxStep: %s\n', ...
    get_param('foc_plant', 'Solver'), get_param('foc_plant', 'FixedStep'), get_param('foc_plant', 'MaxStep'));
