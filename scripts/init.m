%% init.m
% Master initialization script for IPMSM FOC Simulation (MTPA + Field Weakening)

%% Clean workspace paths
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));

%% Load PMSM parameters (IPMSM with Ld != Lq)
run('motor.m');

%% Load Controller parameters, gain tuning, and bus objects
run('controller.m');

%% Default Speed Reference Profile for Testing (RPM)
% Multi-regime ramp profile:
%   0 -> 8,000 RPM (MTPA regime)
%   8,000 -> 18,000 RPM (field weakening above base speed)
%   18,000 -> 6,000 RPM (deceleration back to MTPA regime)
%
% Avoid a discontinuous speed step here. A hard step instantly saturates the
% speed PI, hides current-loop tuning issues, and can make field weakening
% request negative d-axis current before the rotor has accelerated.
foc.simStopTime = 0.80;
t_prof   = [0, 0.05, 0.25, 0.45, 0.60, 0.80];
spd_prof = single([0, 0,    8000, 18000, 18000, 6000]);
sp_ts = timeseries(spd_prof, t_prof);

%% Export all variables to base workspace for Simulink model evaluation
varList = who;
for k = 1:length(varList)
    assignin('base', varList{k}, eval(varList{k}));
end

