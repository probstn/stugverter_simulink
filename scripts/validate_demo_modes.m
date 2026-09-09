%% validate_demo_modes.m
% Lightweight SIL smoke test for supervisor output ownership in every mode.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(simulinkDir, 'scripts'), fullfile(simulinkDir, 'models'));
run(fullfile(simulinkDir, 'scripts', 'init.m'));
model = 'stugverter_sim';
simulation_mode.Value = uint8(0);
assignin('base', 'simulation_mode', simulation_mode);
load_system(fullfile(simulinkDir, 'models', [model '.slx']));

offDuty = runMode(model, uint8(0), false, 0.01);
assert(max(abs(offDuty(:) - 0.5)) < 1e-6, 'OFF must command neutral duty.');

calDuty = runMode(model, uint8(1), true, 0.01);
assert(max(calDuty(:,1)) > 0.51, 'CALIBRATION did not apply alignment voltage.');
assert(max(abs(calDuty(:) - 0.5)) < 0.04, 'CALIBRATION exceeded demo limit.');

openDuty = runMode(model, uint8(2), true, 0.02);
assert(max(openDuty(:)) - min(openDuty(:)) > 0.04, ...
    'OPEN_LOOP did not generate a rotating voltage vector.');
assert(max(abs(openDuty(:) - 0.5)) <= 0.041, 'OPEN_LOOP exceeded demo limit.');

torque_ref_nm.Value = single(1);
assignin('base', 'torque_ref_nm', torque_ref_nm);
torqueDuty = runMode(model, uint8(4), true, 0.02);
assert(any(abs(torqueDuty(:) - 0.5) > 1e-3), ...
    'TORQUE_FOC did not exercise the shared MTPA/current-control path.');

fprintf('[+] OFF, CALIBRATION, OPEN_LOOP and TORQUE_FOC smoke tests passed.\n');

function duty = runMode(model, mode, enabled, stopTime)
enableParam = evalin('base', 'control_enable_request');
modeParam = evalin('base', 'control_mode_request');
enableParam.Value = enabled;
modeParam.Value = mode;
assignin('base', 'control_enable_request', enableParam);
assignin('base', 'control_mode_request', modeParam);
simIn = Simulink.SimulationInput(model);
simIn = setModelParameter(simIn, 'StopTime', num2str(stopTime), ...
    'EnablePacing', 'off');
out = sim(simIn);
duty = out.scope_duty{1}.Values.Data;
end
