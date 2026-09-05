%% controller.m
% Field Oriented Control (FOC) parameters, gain tuning, and bus definitions

%% Controller Timing
foc.Ts = 1/20e3;           % 20 kHz current control loop sample period (50 us)
foc.Ts_speed = 10*foc.Ts;  % 2 kHz speed control sample period
foc.V_utilization = 0.92; % Keep PWM headroom for FW/current regulation
foc.V_phase_max = foc.V_utilization * pmsm.V_rated / sqrt(3);

%% Measurement Bus Definition
clear measurement elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'MtrPos';
elems(1).Dimensions = 1;
elems(1).DataType = 'double';
elems(1).Description = 'Rotor mechanical position [rad]';

elems(2) = Simulink.BusElement;
elems(2).Name = 'currents';
elems(2).Dimensions = 3;
elems(2).DataType = 'double';
elems(2).Description = 'Stator 3-phase currents [A]';

elems(3) = Simulink.BusElement;
elems(3).Name = 'speed';
elems(3).Dimensions = 1;
elems(3).DataType = 'double';
elems(3).Description = 'Rotor mechanical speed [rad/s]';

measurement = Simulink.Bus;
measurement.Elements = elems;
measurement.Description = 'Plant measurement bus';

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
