%% run_hardware.m
% Opens the real-time XCP commissioning console. The TC387 control ISR remains
% autonomous at 20 kHz; Simulink sends commands and speed-profile setpoints at
% 100 Hz and receives decimated DAQ telemetry at 100 Hz.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
modelsDir = fullfile(simulinkDir, 'models');
addpath(fullfile(simulinkDir, 'scripts'), modelsDir);
run(fullfile(simulinkDir, 'scripts', 'init.m'));

modelName = 'stugverter_monitor';
wait_for_xcp('192.168.0.10', 5555, '192.168.0.100', 15);
load_system(fullfile(modelsDir, [modelName '.slx']));
set_param([modelName '/Enable OFF'], 'Value', '0');
set_param([modelName '/Enable ON'], 'Value', '1');
set_param([modelName '/Mode Request'], 'Value', '0');

% Default wall-clock speed profile. The final zero makes a completed profile
% safe even if the Enable switch is left on.
hardware_speed_profile = timeseries(single([0 0 150 300 300 150 0 0]).', ...
    [0 1 3 6 8 10 12 3600].');
assignin('base', 'hardware_speed_profile', hardware_speed_profile);

set_param(modelName, 'StopTime', 'inf', 'EnablePacing', 'on', ...
    'PacingRate', '1');
open_system(modelName);
for scopeName = {'Duty Scope','Current Scope','Speed Scope','Status Scope'}
    try, open_system([modelName '/' scopeName{1}]); catch, end
end

if strcmp(get_param(modelName, 'SimulationStatus'), 'stopped')
    set_param(modelName, 'SimulationCommand', 'start');
end

fprintf('\n[+] Hardware commissioning console is running in real time.\n');
fprintf('    Target control loop: 20 kHz autonomous; XCP command/DAQ: 100 Hz.\n');
fprintf('    Double-click yellow command blocks or the manual switches.\n');
fprintf('    START/STOP: toggle Enable Command. Select mode before enabling.\n');
fprintf('    CALIBRATION: set request 1=current, 2=angle, 3=full; return it to 0 when done.\n');
fprintf('    SPEED PROFILE: toggle Manual/Profile switch to the profile input.\n');
fprintf('    Stop the model only after Enable Command is OFF. A 200 ms target watchdog\n');
fprintf('    disables the gates if XCP commands stop unexpectedly.\n\n');
