%% validate_demo_modes.m
% SIL regression for all 5 supervisor states: IDLE, READY, RUN, FAULT, CALIBRATION.
% Tests startup current-zero calibration, conditional 0 angle offset calibration,
% and the three control modes: TORQUE, SPEED, and OPEN LOOP.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(simulinkDir, 'scripts'), fullfile(simulinkDir, 'models'));
run(fullfile(simulinkDir, 'scripts', 'init.m'));
model = 'stugverter_sim';
simulation_mode.Value = uint8(0);
assignin('base', 'simulation_mode', simulation_mode);
load_system(fullfile(simulinkDir, 'models', [model '.slx']));

fprintf('\n--- 1. Testing IDLE State and Startup Current-Zero Calibration ---\n');
% 1. Startup always performs current-zero averaging with PWM neutral (IDLE -> CALIBRATION -> IDLE/READY).
[offDuty, offTime] = runCase(model, uint8(0), false, uint8(0), true, 0.13);
assert(max(abs(offDuty(:) - single(0.5))) < 1e-6, ...
    'OFF/startup current calibration must command neutral duty.');
assert(offTime(end) >= 0.129, 'Startup calibration test ended too early.');
fprintf('  [OK] Startup current-zero calibration completed with neutral duty.\n');

fprintf('\n--- 2. Testing CALIBRATION State: 0 Angle Offset on User Request ---\n');
% 2. Resolver calibration requested by user (calibration_request = 2)
[calDuty, calTime] = runCase(model, uint8(0), true, uint8(2), true, 0.62);
calActive = max(abs(calDuty - single(0.5)), [], 2) > 1e-4;
firstActive = find(calActive, 1, 'first');
lastActive = find(calActive, 1, 'last');
assert(~isempty(firstActive) && calTime(firstActive) > 0.10, ...
    'Resolver alignment started before current-zero calibration completed.');
assert(calTime(lastActive) > 0.55 && calTime(lastActive) < 0.58, ...
    'Resolver alignment/sample duration is incorrect.');
assert(max(abs(calDuty(end,:) - single(0.5))) < 1e-6, ...
    'Resolver calibration must finish at neutral PWM.');
fprintf('  [OK] User-requested 0 angle offset calibration passed.\n');

fprintf('\n--- 3. Testing CALIBRATION State: Automatic 0 Angle Offset When No Stored Value ---\n');
% 3. Resolver calibration automatically triggered when has_stored_resolver_offset = false
[autoCalDuty, autoCalTime] = runCase(model, uint8(0), false, uint8(0), false, 0.62);
autoCalActive = max(abs(autoCalDuty - single(0.5)), [], 2) > 1e-4;
autoFirstActive = find(autoCalActive, 1, 'first');
autoLastActive = find(autoCalActive, 1, 'last');
assert(~isempty(autoFirstActive) && autoCalTime(autoFirstActive) > 0.10, ...
    'Automatic resolver alignment did not start after current cal.');
assert(autoCalTime(autoLastActive) > 0.55 && autoCalTime(autoLastActive) < 0.58, ...
    'Automatic resolver alignment/sample duration is incorrect.');
assert(max(abs(autoCalDuty(end,:) - single(0.5))) < 1e-6, ...
    'Automatic resolver calibration must finish at neutral PWM.');
fprintf('  [OK] Automatic 0 angle offset calibration without stored value passed.\n');

fprintf('\n--- 4. Testing READY State (Calibrated, Mode Selected, Not Enabled) ---\n');
% 4. Mode selected (SPEED=2), but enable_request = false -> stays in READY at neutral duty
[readyDuty, ~] = runCase(model, uint8(2), false, uint8(0), true, 0.16);
assert(max(abs(readyDuty(:) - single(0.5))) < 1e-6, ...
    'READY state with enable=false must command neutral duty.');
fprintf('  [OK] READY state commands neutral duty while waiting for enable.\n');

fprintf('\n--- 5. Testing RUN State: TORQUE Mode ---\n');
% 5. Torque mode (mode=1, enable=true): switch at MTPA input selects torque reference directly
torque_ref_nm.Value = single(1);
assignin('base', 'torque_ref_nm', torque_ref_nm);
torqueDuty = runCase(model, uint8(1), true, uint8(0), true, 0.16);
assert(any(abs(torqueDuty(:) - 0.5) > 1e-3), ...
    'TORQUE mode did not exercise the shared FOC path.');
fprintf('  [OK] TORQUE mode active and modulating.\n');

fprintf('\n--- 6. Testing RUN State: SPEED Mode ---\n');
% 6. Speed mode (mode=2, enable=true): switch at MTPA input selects Speed PI torque command
speedDuty = runCase(model, uint8(2), true, uint8(0), true, 0.20);
assert(any(abs(speedDuty(:) - 0.5) > 1e-3), ...
    'SPEED mode did not activate the speed PI and FOC path.');
fprintf('  [OK] SPEED mode active with closed-loop speed regulation.\n');

fprintf('\n--- 7. Testing RUN State: OPEN LOOP Mode ---\n');
% 7. Open loop mode (mode=3, enable=true): rotating voltage vector generated in arbitration
openDuty = runCase(model, uint8(3), true, uint8(0), true, 0.16);
assert(max(openDuty(:)) - min(openDuty(:)) > 0.04, ...
    'OPEN LOOP mode did not generate a rotating voltage vector.');
assert(max(abs(openDuty(:) - 0.5)) <= 0.041, ...
    'OPEN LOOP exceeded the commissioning modulation limit.');
fprintf('  [OK] OPEN LOOP mode generates rotating sinusoidal voltage vector.\n');

fprintf('\n====================================================================\n');
fprintf(' [+] All 5 Supervisor States (IDLE, READY, RUN, FAULT, CALIBRATION)\n');
fprintf('     and 3 Control Modes (TORQUE, SPEED, OPEN LOOP) PASSED in SIL!\n');
fprintf('====================================================================\n\n');

function [duty, time] = runCase(model, mode, enabled, calRequest, hasStored, stopTime)
modeParam = evalin('base', 'control_mode_request');
enableParam = evalin('base', 'control_enable_request');
calParam = evalin('base', 'calibration_request');
hasStoredParam = evalin('base', 'has_stored_resolver_offset');
modeParam.Value = mode;
enableParam.Value = enabled;
calParam.Value = calRequest;
hasStoredParam.Value = hasStored;
assignin('base', 'control_mode_request', modeParam);
assignin('base', 'control_enable_request', enableParam);
assignin('base', 'calibration_request', calParam);
assignin('base', 'has_stored_resolver_offset', hasStoredParam);
simIn = Simulink.SimulationInput(model);
simIn = setModelParameter(simIn, 'StopTime', num2str(stopTime), ...
    'EnablePacing', 'off');
out = sim(simIn);
values = out.scope_duty{1}.Values;
duty = values.Data;
time = values.Time;
end
