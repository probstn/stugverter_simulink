%% init.m
% Master initialization script for IPMSM FOC Simulation (MTPA + Field Weakening)

%% Clean workspace paths
if exist('resolve_simulink_dir', 'file') == 2
    rootDir = resolve_simulink_dir();
else
    try
        proj = currentProject;
        rootDir = proj.RootFolder;
    catch
        candidates = {pwd, fullfile(pwd, 'simulink'), fileparts(pwd), ...
                      fullfile(fileparts(pwd), 'simulink'), ...
                      'C:\Users\probst\Desktop\stugverter\simulink'};
        rootDir = pwd;
        for k = 1:length(candidates)
            if exist(fullfile(candidates{k}, 'scripts', 'motor.m'), 'file')
                rootDir = candidates{k};
                break;
            end
        end
    end
end

scriptsDir = fullfile(rootDir, 'scripts');
modelsDir  = fullfile(rootDir, 'models');
if isfolder(scriptsDir), addpath(scriptsDir); end
if isfolder(modelsDir),  addpath(modelsDir);  end

%% Load PMSM parameters (IPMSM with Ld != Lq)
run(fullfile(scriptsDir, 'motor.m'));

%% Load Controller parameters, gain tuning, and bus objects
run(fullfile(scriptsDir, 'controller.m'));

%% Default Speed Reference Profile for Testing (RPM)
% Multi-regime ramp profile:
%   0 -> 8,000 RPM (MTPA regime)
%   8,000 -> 18,000 RPM (field weakening above base speed)
%   18,000 -> 6,000 RPM (deceleration back to MTPA regime)
foc.simStopTime = 0.80;
t_prof   = [0, 0.05, 0.25, 0.45, 0.60, 0.80];
spd_prof = single([0, 0,    8000, 18000, 18000, 6000]);
sp_ts = timeseries(spd_prof(:), t_prof(:));

%% Export all variables to base and caller workspaces for Simulink evaluation
varList = who;
for k = 1:length(varList)
    assignin('base', varList{k}, eval(varList{k}));
    try
        assignin('caller', varList{k}, eval(varList{k}));
    catch
    end
end
