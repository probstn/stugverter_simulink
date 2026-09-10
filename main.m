%% STUGVERTER: COMPLETE SIL -> HIL -> HARDWARE WORKFLOW
% Open stugverter.prj, open this file in the MATLAB Editor, then run one
% section at a time with Ctrl+Enter. Do not run the complete file at once.
%
% Active commissioning configuration:
%   Fixed assumed DC bus:       20 V
%   Controller current limit:   0.80 A peak
%   Software current trip:      0.90 A peak
%   Power-supply limit:         set externally to 20 V / 1 A
%
% Control modes: 0=OFF, 1=TORQUE, 2=SPEED, 3=OPEN_LOOP
% Calibration:   0=NONE, 1=CURRENT_ZERO, 2=RESOLVER_ZERO, 3=FULL
%
% Workflow Structure:
%   Step 1: Run SIL Simulation (generates sil_results.mat)
%   Step 2: Verify SIL Modes & Supervisor Logic
%   Step 3: Generate Embedded C Code (Embedded Coder)
%   Step 4: Deploy Generated C Code into TC387 Firmware Project
%   Step 5: Build & Flash Infineon AURIX TC387 Target via winIDEA
%   Step 6: Run HIL Simulation with Target (generates hil_results.mat)
%   Step 7: Compare SIL vs HIL (loads prior results directly; does not re-simulate)
%   Step 8: Launch Hardware Commissioning Dashboard Monitor (stugverter_monitor.slx)

simulinkDir = currentProject().RootFolder;
addpath(fullfile(simulinkDir, 'scripts'), fullfile(simulinkDir, 'models'));

%% 1. SIL: Simulate controller and Fischer motor plant in Simulink
% Runs the 20 V / <1 A speed profile with the pure Simulink SIL controller.
% Saves simulation output to simulink/sil_results.mat and workspace 'silOut'.
run(fullfile(simulinkDir, 'scripts', 'step1_run_sil.m'));

%% 2. SIL: Supervisor & mode regression verification
% Verifies boot current-zero calibration, conditional resolver calibration,
% IDLE, READY, RUN, FAULT-safe duty, and torque/speed/open-loop transitions.
run(fullfile(simulinkDir, 'scripts', 'step2_verify_sil_modes.m'));

%% 3. Code Generation: Generate embedded C code via Embedded Coder
% Compiles algorithm.slx with the updated 32-bit fault word (g_fault_flags).
run(fullfile(simulinkDir, 'scripts', 'step3_generate_code.m'));

%% 4. Deploy: Copy generated code into TC387 firmware project
% Copies generated source and headers to firmware/algorithm/.
run(fullfile(simulinkDir, 'scripts', 'step4_deploy_code.m'));

%% 5. Flash: Compile firmware and flash AURIX TC387 via winIDEA
% Connects to winIDEA, flashes firmware.elf, verifies safe neutral boot:
% PWM=[0.5, 0.5, 0.5], gate drivers disabled, enable request cleared.
run(fullfile(simulinkDir, 'scripts', 'step5_flash_target.m'));

%% 6. HIL: Simulated plant with real TC387 controller over XCP UDP
% Injects plant feedback via XCP STIM and acquires target PWM duties in lockstep.
% Saves target simulation results to simulink/hil_results.mat and workspace 'hilOut'.
run(fullfile(simulinkDir, 'scripts', 'step6_run_hil.m'));

%% 7. Compare SIL and HIL: Compare previous independent runs
% Compares results from Step 1 (sil_results.mat) and Step 6 (hil_results.mat).
% NOTE: This step DOES NOT re-run simulations; it compares the prior data directly.
run(fullfile(simulinkDir, 'scripts', 'step7_compare_sil_hil.m'));

%% 8. ACTUAL HARDWARE: Open interactive real-time XCP dashboard monitor
% Launches stugverter_monitor.slx containing the formatted HMI dashboard:
%   - 20 kHz telemetry DAQ (control loop speed)
%   - Master enable toggle,the calib mode selector (OFF, TORQUE, SPEED, OPEN_LOOP)
%   - Manual speed reference with a conservative 300 rpm commissioning limit
%   - Open-loop controls (Frequency 0.2-2 Hz, Modulation 0.001-0.01)
%   - Calibration controls (Current zero, Resolver zero offset display in deg/rad)
%   - Fault bit indicators (unpacked from uint32 g_fault_flags) and Fault Reset
%   - Real-time rotor speed waveform scope and radial speedometer gauge
run(fullfile(simulinkDir, 'scripts', 'step8_run_hardware_monitor.m'));

%% 9. Manual hardware controls (optional script commands during live monitor)
% You can use the interactive dashboard switches directly in the model,
% or run these commands from the MATLAB command window:
%
% Enable Speed Mode at 100 RPM:
%   set_param('stugverter_monitor/Communications Backend/Mode Request', 'Value', '2');
%   set_param('stugverter_monitor/Communications Backend/Manual Speed', 'Value', '100');
%
% Open Loop Mode (e.g. 1 Hz, 0.001 modulation for Fischer motor spinning test):
%   set_param('stugverter_monitor/Communications Backend/Mode Request', 'Value', '3');
%   set_param('stugverter_monitor/Communications Backend/Open Loop Hz', 'Value', '1.0');
%   set_param('stugverter_monitor/Communications Backend/Open Loop Modulation', 'Value', '0.001');
%
% Trigger Resolver Angle Calibration (Fischer motor must be free to align):
%   set_param('stugverter_monitor/Communications Backend/Calibration Request', 'Value', '2');
%   pause(1.0);
%   set_param('stugverter_monitor/Communications Backend/Calibration Request', 'Value', '0');

%% 10. Safe shutdown
% Turn OFF Enable switch, set Mode to 0 (OFF), and stop the monitor model.
% The target MCU has an autonomous 200 ms watchdog that safely disables gates
% if communication is interrupted.
set_param('stugverter_monitor/Communications Backend/Enable Request Value', 'Value', '0');
set_param('stugverter_monitor/Communications Backend/Mode Request', 'Value', '0');
set_param('stugverter_monitor/Communications Backend/Calibration Request', 'Value', '0');
pause(0.10);
set_param('stugverter_monitor', 'SimulationCommand', 'stop');
