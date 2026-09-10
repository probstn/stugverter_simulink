%% init.m
% Master initialization script for IPMSM FOC Simulation (MTPA + Field Weakening)

%% Resolve relative to this script (independent of MATLAB's current folder).
rootDir = fileparts(fileparts(mfilename('fullpath')));

scriptsDir = fullfile(rootDir, 'scripts');
modelsDir  = fullfile(rootDir, 'models');
if isfolder(scriptsDir), addpath(scriptsDir); end
if isfolder(modelsDir),  addpath(modelsDir);  end

% Keep generated caches out of the source/script folders. Code generation
% remains rooted at simulink/ so the deploy workflow keeps its stable path.
try
    Simulink.fileGenControl('set', ...
        'CacheFolder', fullfile(rootDir, 'slprj'), ...
        'CodeGenFolder', rootDir, 'createDir', true);
catch ME
    % Model callbacks also invoke init while a code-generation build is
    % active; file-generation folders cannot be changed in that phase.
    if ~contains(ME.message, 'Build in progress')
        rethrow(ME);
    end
end

%% Load PMSM parameters (IPMSM with Ld != Lq)
run(fullfile(scriptsDir, 'motor_params.m'));

%% Load Controller parameters, gain tuning, and bus objects
% Preserve tunable commissioning commands across model InitFcn callbacks.
commandNames = {'control_mode_request', 'control_enable_request', ...
    'control_fault_reset', 'calibration_request', 'torque_ref_nm', ...
    'current_offset_counts', 'open_loop_electrical_hz', ...
    'open_loop_modulation', 'calibration_modulation', 'resolver_angle_offset', ...
    'has_stored_resolver_offset', 'simulation_mode', 'hil_control_mode_request'};
for commandIndex = 1:numel(commandNames)
    commandName = commandNames{commandIndex};
    if evalin('base', sprintf('exist(''%s'', ''var'')', commandName))
        eval([commandName ' = evalin(''base'', commandName);']);
    end
end
run(fullfile(scriptsDir, 'controller_params.m'));

%% Default Speed Reference Profile for Testing (RPM)
% Multi-regime ramp profile:
%   Startup: 0..0.15s calibration
%   0 -> 8,000 RPM (MTPA regime)
%   8,000 -> 18,000 RPM (field weakening above base speed)
%   18,000 -> 6,000 RPM (deceleration back to MTPA regime)
foc.simStopTime = 0.90;
t_prof   = [0, 0.15, 0.35, 0.55, 0.70, 0.90];
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
