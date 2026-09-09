%% init.m
% Master initialization script for IPMSM FOC Simulation (MTPA + Field Weakening)

%% Resolve relative to this script (independent of MATLAB's current folder).
rootDir = fileparts(fileparts(mfilename('fullpath')));

scriptsDir = fullfile(rootDir, 'scripts');
modelsDir  = fullfile(rootDir, 'models');
if isfolder(scriptsDir), addpath(scriptsDir); end
if isfolder(modelsDir),  addpath(modelsDir);  end

%% Load PMSM parameters (IPMSM with Ld != Lq)
run(fullfile(scriptsDir, 'motor_params.m'));

%% Load Controller parameters, gain tuning, and bus objects
% Preserve tunable commissioning commands across model InitFcn callbacks.
commandNames = {'control_mode_request', 'control_enable_request', ...
    'control_fault_reset', 'torque_ref_nm', 'open_loop_electrical_hz', ...
    'open_loop_modulation', 'calibration_modulation', 'resolver_angle_offset', ...
    'simulation_mode', 'hil_control_mode_request'};
for commandIndex = 1:numel(commandNames)
    commandName = commandNames{commandIndex};
    if evalin('base', sprintf('exist(''%s'', ''var'')', commandName))
        eval([commandName ' = evalin(''base'', commandName);']);
    end
end
run(fullfile(scriptsDir, 'controller_params.m'));

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
