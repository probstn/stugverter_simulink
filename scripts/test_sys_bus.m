% test_sys_bus.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
bs = 'foc_system/Bus Selector1';
fprintf('Bus Selector1 OutputSignals in foc_system: %s\n', get_param(bs, 'OutputSignals'));
