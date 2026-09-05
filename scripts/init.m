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
% Multi-regime profile:
%   0 -> 8,000 RPM (MTPA regime)
%   8,000 -> 18,000 RPM (Field Weakening regime above base speed)
%   18,000 -> 6,000 RPM (Deceleration back to MTPA regime)
t_prof   = [0,   0.05,   0.20,   0.40,   0.60,   0.75,  0.90];
spd_prof = [0,      0,   8000,  18000,  18000,   6000,  6000];
sp_ts = timeseries(spd_prof, t_prof);