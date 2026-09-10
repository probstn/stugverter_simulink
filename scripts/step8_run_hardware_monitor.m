%% step8_run_hardware_monitor.m
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
backend = [modelName '/Communications Backend'];
set_param([backend '/Enable Request Value'], 'Value', '0');
set_param([backend '/Mode Request'], 'Value', '0');
set_param([backend '/Calibration Request'], 'Value', '0');
set_param([backend '/Execute Calibration'], 'Value', '0');
set_param([backend '/Fault Reset'], 'Value', '0');
set_param([backend '/Torque Reference'], 'Value', '0');
set_param([backend '/Manual Speed'], 'Value', '0');
set_param([backend '/Open Loop Hz'], 'Value', '0.5');
set_param([backend '/Open Loop Modulation'], 'Value', '0.001');
set_param([backend '/Calibration Modulation'], 'Value', '0.005');

set_param(modelName, 'StopTime', 'inf', 'EnablePacing', 'on', ...
    'PacingRate', '1');
open_system(modelName);

if strcmp(get_param(modelName, 'SimulationStatus'), 'stopped')
    set_param(modelName, 'SimulationCommand', 'start');
end

% Verify the live target is de-energized before presenting the console. Clear
% only non-tripping startup annunciators after current-zero has settled.
pause(0.35);
daq = get_param([backend '/XCP UDP Data Acquisition'], 'RuntimeObject');
activeMode = double(daq.OutputPort(9).Data);
pwmPermission = double(daq.OutputPort(10).Data);
gatesEnabled = double(daq.OutputPort(11).Data);
faultWord = uint32(daq.OutputPort(21).Data);
if activeMode ~= 0 || pwmPermission ~= 0 || gatesEnabled ~= 0 || bitand(faultWord, uint32(256)) ~= 0
    set_param([backend '/Enable Request Value'], 'Value', '0');
    set_param([backend '/Mode Request'], 'Value', '0');
    set_param(modelName, 'SimulationCommand', 'stop');
    error('Unsafe target state at dashboard start: mode=%g pwm=%g gates=%g faults=0x%08X.', ...
        activeMode, pwmPermission, gatesEnabled, faultWord);
end
if faultWord ~= 0
    set_param([backend '/Fault Reset'], 'Value', '1');
    pause(0.15);
    set_param([backend '/Fault Reset'], 'Value', '0');
end

fprintf('\n[+] Hardware commissioning console is running in real time.\n');
fprintf('    Target control loop: 20 kHz autonomous; XCP command/DAQ: 100 Hz.\n');
fprintf('    Supply assumption: 20 V with external 1 A current limit.\n');
fprintf('    START/STOP: select one mode with Enable OFF, set a low reference, then Enable.\n');
fprintf('    CALIBRATION: choose CURRENT, ANGLE, or BOTH, then click RUN CALIBRATION.\n');
fprintf('    The momentary button automatically returns the effective request to NONE.\n');
fprintf('    Stop the model only after Enable is OFF. A 200 ms target watchdog\n');
fprintf('    disables the gates if XCP commands stop unexpectedly.\n\n');
