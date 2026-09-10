%% controller_params.m
% Field Oriented Control (FOC) parameters, gain tuning, and bus definitions

%% Controller Timing
foc.Ts = 1/20e3;           % 20 kHz current control loop sample period (50 us)
foc.Ts_speed = 10*foc.Ts;  % 2 kHz speed control sample period
foc.hilPacingRate = 0.02;  % Simulated seconds per wall-clock second for reliable XCP HIL
foc.V_utilization = 0.92; % Keep PWM headroom for FW/current regulation
foc.V_phase_max = foc.V_utilization * pmsm.V_rated / sqrt(3);

%% Supervisor commands and conservative commissioning limits
% Operating modes: 0=OFF, 1=TORQUE, 2=SPEED, 3=OPEN_LOOP.
% Calibration is a separate request because it is a procedure, not a mode:
% 0=NONE, 1=CURRENT_ZERO, 2=RESOLVER_ZERO, 3=FULL.
if ~exist('control_mode_request', 'var') || ~isa(control_mode_request, 'Simulink.Parameter')
    control_mode_request = Simulink.Parameter(uint8(0));
end
control_mode_request.DataType = 'uint8';
control_mode_request.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('control_enable_request', 'var') || ~isa(control_enable_request, 'Simulink.Parameter')
    control_enable_request = Simulink.Parameter(false);
end
control_enable_request.DataType = 'boolean';
control_enable_request.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('control_fault_reset', 'var') || ~isa(control_fault_reset, 'Simulink.Parameter')
    control_fault_reset = Simulink.Parameter(false);
end
control_fault_reset.DataType = 'boolean';
control_fault_reset.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('calibration_request', 'var') || ~isa(calibration_request, 'Simulink.Parameter')
    calibration_request = Simulink.Parameter(uint8(0));
end
calibration_request.DataType = 'uint8';
calibration_request.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('torque_ref_nm', 'var') || ~isa(torque_ref_nm, 'Simulink.Parameter')
    torque_ref_nm = Simulink.Parameter(single(0));
end
torque_ref_nm.DataType = 'single';
torque_ref_nm.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('open_loop_electrical_hz', 'var') || ~isa(open_loop_electrical_hz, 'Simulink.Parameter')
    open_loop_electrical_hz = Simulink.Parameter(single(2));
end
open_loop_electrical_hz.DataType = 'single';
open_loop_electrical_hz.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('open_loop_modulation', 'var') || ~isa(open_loop_modulation, 'Simulink.Parameter')
    open_loop_modulation = Simulink.Parameter(single(0.0015));
end
open_loop_modulation.DataType = 'single';
open_loop_modulation.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('calibration_modulation', 'var') || ~isa(calibration_modulation, 'Simulink.Parameter')
    % Produces approximately 0.15 V line-to-line at the fixed 20 V bus,
    % corresponding to roughly 0.6 A with the measured phase resistance.
    calibration_modulation = Simulink.Parameter(single(0.005));
end
calibration_modulation.DataType = 'single';
calibration_modulation.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('resolver_angle_offset', 'var') || ~isa(resolver_angle_offset, 'Simulink.Parameter')
    resolver_angle_offset = Simulink.Parameter(single(2.418204));
end
resolver_angle_offset.DataType = 'single';
resolver_angle_offset.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('current_offset_counts', 'var') || ~isa(current_offset_counts, 'Simulink.Parameter')
    current_offset_counts = Simulink.Parameter(single([2051.155; 2056.162; 2052.236]));
end
current_offset_counts.DataType = 'single';
current_offset_counts.CoderInfo.StorageClass = 'ExportedGlobal';
if ~exist('has_stored_resolver_offset', 'var') || ~isa(has_stored_resolver_offset, 'Simulink.Parameter')
    has_stored_resolver_offset = Simulink.Parameter(true);
end
has_stored_resolver_offset.DataType = 'boolean';
has_stored_resolver_offset.CoderInfo.StorageClass = 'ExportedGlobal';

% Runtime calibration results are exported so commissioning tools can read
% them and copy the accepted values back into the initial parameters above.
resolver_offset_runtime = Simulink.Signal;
resolver_offset_runtime.DataType = 'single';
resolver_offset_runtime.Dimensions = 1;
resolver_offset_runtime.CoderInfo.StorageClass = 'ExportedGlobal';
current_offsets_runtime = Simulink.Signal;
current_offsets_runtime.DataType = 'single';
current_offsets_runtime.Dimensions = 3;
current_offsets_runtime.CoderInfo.StorageClass = 'ExportedGlobal';

% Simulation harness variant: 0=SIL controller, 1=TC387/XCP HIL controller.
% This variable selects a compile-time variant so XCP is not initialized in SIL.
if ~exist('simulation_mode', 'var') || ~isa(simulation_mode, 'Simulink.Parameter')
    simulation_mode = Simulink.Parameter(uint8(0));
end
simulation_mode.DataType = 'uint8';
if ~exist('hil_control_mode_request', 'var') || ~isa(hil_control_mode_request, 'Simulink.Parameter')
    hil_control_mode_request = Simulink.Parameter(uint8(2));
end
hil_control_mode_request.DataType = 'uint8';

protection.current_trip_A = single(0.90);
protection.overspeed_rads = single(20000 * 2*pi/60);
protection.resolver_min_amplitude = single(0.10);
protection.resolver_max_amplitude = single(1.30);
protection.adc_rail_low = uint16(8);
protection.adc_rail_high = uint16(4087);

%% Measurement Bus Definitions
% Plant Measurement Bus (Continuous double for Simscape / physical motor)
clear plant_measurement plant_elems;
plant_elems(1) = Simulink.BusElement;
plant_elems(1).Name = 'MtrPos';
plant_elems(1).Dimensions = 1;
plant_elems(1).DataType = 'double';
plant_elems(1).Description = 'Rotor mechanical position [rad]';

plant_elems(2) = Simulink.BusElement;
plant_elems(2).Name = 'currents';
plant_elems(2).Dimensions = 3;
plant_elems(2).DataType = 'double';
plant_elems(2).Description = 'Stator 3-phase currents [A]';

plant_elems(3) = Simulink.BusElement;
plant_elems(3).Name = 'speed';
plant_elems(3).Dimensions = 1;
plant_elems(3).DataType = 'double';
plant_elems(3).Description = 'Rotor mechanical speed [rad/s]';

plant_measurement = Simulink.Bus;
plant_measurement.Elements = plant_elems;
plant_measurement.Description = 'Physical plant measurement bus (continuous double)';

% Algorithm Measurement Bus (Discrete single precision for embedded controller)
clear algo_measurement algo_elems;
algo_elems(1) = Simulink.BusElement;
algo_elems(1).Name = 'MtrPos';
algo_elems(1).Dimensions = 1;
algo_elems(1).DataType = 'single';
algo_elems(1).Description = 'Rotor mechanical position [rad]';

algo_elems(2) = Simulink.BusElement;
algo_elems(2).Name = 'currents';
algo_elems(2).Dimensions = 3;
algo_elems(2).DataType = 'single';
algo_elems(2).Description = 'Stator 3-phase currents [A]';

algo_elems(3) = Simulink.BusElement;
algo_elems(3).Name = 'speed';
algo_elems(3).Dimensions = 1;
algo_elems(3).DataType = 'single';
algo_elems(3).Description = 'Rotor mechanical speed [rad/s]';

algo_measurement = Simulink.Bus;
algo_measurement.Elements = algo_elems;
algo_measurement.Description = 'Algorithm internal sensor bus (pure single precision)';

% Keep measurement as alias to plant_measurement for legacy references if any
measurement = plant_measurement;

%% ADC Values Bus Definition (12-bit AURIX TC387 EVADC)
clear adc_elems adc_values;
adc_elems(1) = Simulink.BusElement;
adc_elems(1).Name = 'ia';
adc_elems(1).Dimensions = 1;
adc_elems(1).DataType = 'uint16';
adc_elems(1).Description = 'Phase A current ADC count [0..4095]';

adc_elems(2) = Simulink.BusElement;
adc_elems(2).Name = 'ib';
adc_elems(2).Dimensions = 1;
adc_elems(2).DataType = 'uint16';
adc_elems(2).Description = 'Phase B current ADC count [0..4095]';

adc_elems(3) = Simulink.BusElement;
adc_elems(3).Name = 'ic';
adc_elems(3).Dimensions = 1;
adc_elems(3).DataType = 'uint16';
adc_elems(3).Description = 'Phase C current ADC count [0..4095]';

adc_elems(4) = Simulink.BusElement;
adc_elems(4).Name = 'resolver_sin';
adc_elems(4).Dimensions = 1;
adc_elems(4).DataType = 'uint16';
adc_elems(4).Description = 'Resolver SIN ADC count [0..4095]';

adc_elems(5) = Simulink.BusElement;
adc_elems(5).Name = 'resolver_cos';
adc_elems(5).Dimensions = 1;
adc_elems(5).DataType = 'uint16';
adc_elems(5).Description = 'Resolver COS ADC count [0..4095]';

adc_values = Simulink.Bus;
adc_values.Elements = adc_elems;
adc_values.Description = '12-bit AURIX TC387 EVADC discrete measurements bus';

%% Sensor & ADC Parameters (AURIX TC387 EVADC)
sensor.ADC_bits = 12;
sensor.ADC_max = 4095;
sensor.ADC_mid = 2048;
sensor.ADC_span = 2047;
sensor.I_max = 120.0;                   % Current sensor full-scale range [A]
sensor.V_ref = 5.0;                     % ADC reference voltage [V]
sensor.speed_fc = 150.0;                % Low-pass filter for speed estimation from resolver [Hz]
sensor.speed_alpha = (2*pi*sensor.speed_fc*foc.Ts) / (1 + 2*pi*sensor.speed_fc*foc.Ts);


%% Motor & Inverter Parameters
lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm); % Fundamental torque constant [Nm/A_peak]

%% Current Controller Gains Tuning (Saliency-aware: Ld != Lq)
% Current loop bandwidth
foc.current_bw_hz = single(800);
foc.omega_c = single(2*pi * double(foc.current_bw_hz));

% Direct-axis (d-axis) PI gains
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Ki_d_Ts = single(foc.Ki_d * foc.Ts);

% Quadrature-axis (q-axis) PI gains
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);
foc.Ki_q_Ts = single(foc.Ki_q * foc.Ts);

%% Speed Controller Gains Tuning (Direct Torque Reference Output)
% Speed loop closed-loop transfer function: (Kp*s + Ki) / (J*s^2 + Kp*s + Ki)
foc.speed_bw_hz = single(20);
foc.wn_s   = single(2*pi * double(foc.speed_bw_hz));
foc.zeta_s = single(1.0);       % Critically damped (zeta = 1.0)
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J); % [Nm / (rad/s)]
foc.Ki_spd = single(pmsm.J * foc.wn_s^2);                % [Nm / rad]
