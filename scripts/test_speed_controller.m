% test_speed_controller.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_speedcontroller');
spd_pi = 'foc_speedcontroller/PI Controller';
fprintf('Speed PI parameters:\n');
fprintf('  P: %s\n', get_param(spd_pi, 'P'));
fprintf('  I: %s\n', get_param(spd_pi, 'I'));
fprintf('  InitialConditionForIntegrator: %s\n', get_param(spd_pi, 'InitialConditionForIntegrator'));
fprintf('  TimeDomain: %s\n', get_param(spd_pi, 'TimeDomain'));
fprintf('  SampleTime: %s\n', get_param(spd_pi, 'SampleTime'));
fprintf('  IntegratorMethod: %s\n', get_param(spd_pi, 'IntegratorMethod'));
