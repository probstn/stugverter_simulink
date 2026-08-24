%% init.m

clear;
clc;

%% Load PMSM parameters
run('motor.m');

%% Load controller parameters and bus objects
run('controller.m');

%% Other initialization scripts
% run('inverter.m');
% run('resolver.m');
% run('adc.m');

open_system("foc_system")
