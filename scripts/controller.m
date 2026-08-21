%% controller.m
% Field Oriented Control (FOC) parameters and bus definitions

%% Controller Timing
foc.Ts = 1/20e3;  % 20 kHz current control loop

%% Measurement Bus Definition (Single Precision)
clear measurement;
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
measurement.Description = 'Plant measurement bus (single precision)';

%% Motor & Inverter Parameters
lambda_pm = 0.2205;
Kt = single(1.5 * pmsm.P * lambda_pm);

%% Controller Gains Tuning (Single Precision)
% Current Loop (1000 Hz bandwidth)
foc.omega_c = single(2*pi * 1000);
foc.Kp_d = 100;
foc.Ki_d = 0;
foc.Kp_q = single(pmsm.Lph * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

% Speed Loop (8 Hz natural frequency, zeta = 1.5 for overdamped tracking)
foc.wn_s = single(2*pi * 8);
foc.zeta_s = single(1.5);
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J / Kt);
foc.Ki_spd = single(pmsm.J * foc.wn_s^2 / Kt);
