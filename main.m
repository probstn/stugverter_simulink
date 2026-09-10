%% STUGVERTER: COMPLETE SIL -> HIL -> HARDWARE WORKFLOW
% Open stugverter.prj, open this file in the MATLAB Editor, then run one
% section at a time with Ctrl+Enter. Do not run the complete file at once.
%
% Active commissioning configuration:
%   Fixed assumed DC bus:       40 V (there is no DC-bus sensor yet)
%   Controller current limit:   0.80 A peak
%   Software current trip:      0.90 A peak
%   Power-supply limit:         set externally to 40 V / 1 A
%
% Control modes: 0=OFF, 1=TORQUE, 2=SPEED, 3=OPEN_LOOP
% Calibration:   0=NONE, 1=CURRENT_ZERO, 2=ANGLE_ZERO, 3=FULL

simulinkDir = fileparts(mfilename('fullpath'));
addpath(fullfile(simulinkDir, 'scripts'), fullfile(simulinkDir, 'models'));

%% 1. SIL: simulate the controller and plant
% Runs the 40 V / <1 A speed profile with the controller inside Simulink.
run(fullfile(simulinkDir, 'scripts', 'run_simulation.m'));

%% 2. SIL supervisor/mode regression
% Verifies boot current calibration, conditional angle calibration, IDLE,
% READY, RUN, FAULT-safe duty, and torque/speed/open-loop selection.
run(fullfile(simulinkDir, 'scripts', 'validate_demo_modes.m'));

%% 3. Generate embedded C code
run(fullfile(simulinkDir, 'scripts', 'generate_code.m'));

%% 4. Deploy generated controller into the TC387 firmware project
run(fullfile(simulinkDir, 'scripts', 'deploy_code.m'));

%% 5. Build, flash, and verify safe TC387 boot
% The flash script requires winIDEA to be open and connected. It verifies
% neutral PWM, gate drivers disabled, and enable request cleared after reset.
run(fullfile(simulinkDir, 'scripts', 'flash_target.m'));

%% 6. HIL: simulated plant with the real TC387 controller over XCP
% HIL STIM is paced for reliable Windows/UDP exchange. The algorithm sample
% time remains 50 us; pacing never changes the controller discretization.
run(fullfile(simulinkDir, 'scripts', 'run_hil.m'));

%% 7. Compare SIL and HIL on a common 50 us grid
run(fullfile(simulinkDir, 'scripts', 'validate_sil_hil.m'));

%% 8. ACTUAL HARDWARE: open the real-time XCP commissioning console
% Preconditions before applying the DC supply:
%   - Emergency stop and hardware overcurrent/desaturation path verified.
%   - Power supply set to 40 V with a hard 1 A current limit.
%   - Motor mechanically secured and resolver polarity checked.
%   - Begin with Enable=OFF, Mode=OFF, Manual Speed=0.
%
% run_hardware opens stugverter_monitor.slx and starts it asynchronously.
% The TC387 control ISR continues at 20 kHz. Simulink exchanges commands and
% telemetry at 100 Hz, in real wall-clock time, without throttling control.
run(fullfile(simulinkDir, 'scripts', 'run_hardware.m'));

%% 9. Manual hardware controls (run individual lines while monitor is running)
% First select a mode, then switch Enable Command ON in the model.
set_param('stugverter_monitor/Mode Request', 'Value', '2');       % SPEED
set_param('stugverter_monitor/Manual Speed', 'Value', '100');     % RPM
% Use the Enable Command manual switch in the model to start/stop.
% Change mode only after Enable is OFF; the supervisor enforces re-arming.
%
% Other modes:
% set_param('stugverter_monitor/Mode Request', 'Value', '1');     % TORQUE
% set_param('stugverter_monitor/Torque Reference', 'Value', '0.05'); % Nm
% set_param('stugverter_monitor/Mode Request', 'Value', '3');     % OPEN LOOP
% set_param('stugverter_monitor/Open Loop Hz', 'Value', '1');
% set_param('stugverter_monitor/Open Loop Modulation', 'Value', '0.001');

%% 10. Manual calibrations over XCP
% Current zero: gates remain disabled. Always runs automatically at boot.
set_param('stugverter_monitor/Calibration Request', 'Value', '1');
pause(0.25);
set_param('stugverter_monitor/Calibration Request', 'Value', '0');
% Angle zero (ONLY with the 40 V / 1 A supply limit and secured motor):
% set_param('stugverter_monitor/Calibration Request', 'Value', '2');
% pause(1.0);
% set_param('stugverter_monitor/Calibration Request', 'Value', '0');

%% 11. Run a real-time speed profile through XCP STIM
% Edit hardware_speed_profile in run_hardware.m if needed. In the monitor,
% switch Manual/Profile to the profile input, select SPEED, then enable.
% Profile samples are sent at 100 Hz while the target loop remains at 20 kHz.

%% 12. Safe shutdown
% Toggle Enable Command OFF first, then stop the model. The target also has a
% 200 ms XCP-command watchdog for cable/model failures.
set_param('stugverter_monitor/Enable OFF', 'Value', '0');
set_param('stugverter_monitor/Enable ON', 'Value', '0');
set_param('stugverter_monitor/Mode Request', 'Value', '0');
pause(0.10); % allow several 100 Hz STIM frames to reach the target
set_param('stugverter_monitor', 'SimulationCommand', 'stop');
