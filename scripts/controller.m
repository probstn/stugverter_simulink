%% controller.m
% Field Oriented Control (FOC) parameters, gain tuning, and bus definitions

%% Controller Timing
foc.Ts = 1/20e3;           % 20 kHz current control loop sample period (50 us)
foc.Ts_speed = 10*foc.Ts;  % 2 kHz speed control sample period
foc.hilPacingRate = 0.02;  % Simulated seconds per wall-clock second for reliable XCP HIL
foc.V_utilization = 0.92; % Keep PWM headroom for FW/current regulation
foc.V_phase_max = foc.V_utilization * pmsm.V_rated / sqrt(3);

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
