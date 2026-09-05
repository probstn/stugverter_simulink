% test_tuned_speed_controller.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

% 1. Clean IPMSM Motor Parameters (Fischer TI085-052-070-04B7S IPMSM)
pmsm.P        = 4;          % Pole pairs
pmsm.Rs       = 0.126;      % Phase resistance [Ohm]
pmsm.Ld       = 0.35e-3;    % d-axis Inductance [H]
pmsm.Lq       = 0.55e-3;    % q-axis Inductance [H] (Lq > Ld for IPMSM)
pmsm.Ldq      = [pmsm.Ld, pmsm.Lq];
pmsm.Ke_data  = 0.296;      % BEMF constant [Vrms_LL/(rad/s)]
pmsm.J        = 0.33e-3;    % Rotor inertia [kg*m^2]
pmsm.B        = 1e-4;       % Viscous damping [Nm/(rad/s)]
pmsm.V_rated  = 600;        % DC bus voltage [V]
pmsm.I_rated  = 86.0;       % Peak phase current limit [A]
pmsm.T_peak   = 29.1;       % Peak torque [Nm]
pmsm.T_rated  = 11.1;       % Nominal torque [Nm]
pmsm.N_base   = 13650;      % Base speed [rpm]
pmsm.N_max    = 20000;      % Maximum speed with field weakening [rpm]

pmsm.fl       = 0.0604;     % PM flux linkage [Wb]
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [pmsm.J pmsm.B 0];

% 2. Controller Gains
foc.Ts = 1/20e3;  % 20 kHz current control loop
foc.omega_c = single(2*pi * 500); % 500 Hz current loop bandwidth for smooth response
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm);

% Speed loop tuning (5 Hz bandwidth, critically damped)
foc.wn_s = single(2*pi * 5); 
foc.zeta_s = single(1.0);     
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J / Kt);
foc.Ki_spd = single(pmsm.J * foc.wn_s^2 / Kt);

% Bus Definition
clear measurement elems;
elems(1) = Simulink.BusElement; elems(1).Name = 'MtrPos'; elems(1).Dimensions = 1; elems(1).DataType = 'double';
elems(2) = Simulink.BusElement; elems(2).Name = 'currents'; elems(2).Dimensions = 3; elems(2).DataType = 'double';
elems(3) = Simulink.BusElement; elems(3).Name = 'speed'; elems(3).Dimensions = 1; elems(3).DataType = 'double';
measurement = Simulink.Bus;
measurement.Elements = elems;
measurement.Description = 'Plant measurement bus';

% Load Models
load_system('foc_system');
load_system('foc_controller');
load_system('foc_plant');
load_system('foc_speedcontroller');

% Configure MTPA block
mtpa_blk = 'foc_system/MTPA Control Reference';
set_param(mtpa_blk, ...
    'Ld', 'pmsm.Ld', ...
    'Lq', 'pmsm.Lq', ...
    'polePairs', 'pmsm.P', ...
    'Rs', 'pmsm.Rs', ...
    'FluxPM', 'pmsm.fl', ...
    'ilimit', 'pmsm.I_rated', ...
    'V_dc', 'pmsm.V_rated', ...
    'N_base', 'pmsm.N_base', ...
    'Units', 'SI Units', ...
    'Vdc_input_select', 'Specify via dialog', ...
    'VariantSelect', 'Interior PMSM');

% Configure Speed Controller
spd_pi = 'foc_speedcontroller/PI Controller';
set_param(spd_pi, ...
    'P', 'foc.Kp_spd', ...
    'I', 'foc.Ki_spd', ...
    'UpperSaturationLimit', 'pmsm.T_peak', ...
    'LowerSaturationLimit', '-pmsm.T_peak');

% Configure Plant
set_param('foc_plant/Interior PMSM', 'Ldq', 'pmsm.Ldq', 'mechanical', 'pmsm.mechanical');

% Configure Current Controller PIs
set_param('foc_controller/Id Controller', 'P', 'foc.Kp_d', 'I', 'foc.Ki_d');
set_param('foc_controller/Iq Controller', 'P', 'foc.Kp_q', 'I', 'foc.Ki_q');

% Set solver settings for high accuracy and stability
set_param('foc_system', 'MaxStep', '1e-5');

% Test Step to 8000 RPM (MTPA region)
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '8000');
set_param('foc_system', 'StopTime', '0.15');

fprintf('Running simulation for MTPA (0 -> 8000 RPM)...\n');
out = sim('foc_system');
logs = out.logsout;
spd_data = logs.get('Speed_Meas').Values;
t = spd_data.Time;
spd = spd_data.Data * (30/pi);
id_r = logs.get('id_ref').Values.Data;
iq_r = logs.get('iq_ref').Values.Data;
id_a = logs.get('id_actual').Values.Data;
iq_a = logs.get('iq_actual').Values.Data;

fprintf('Results at t = 0.15 s:\n');
fprintf('  Speed = %.1f RPM (Target = 8000 RPM)\n', spd(end));
fprintf('  Max Speed = %.1f RPM\n', max(spd));
fprintf('  id_ref min/max = %.2f / %.2f A\n', min(id_r), max(id_r));
fprintf('  id_act min/max = %.2f / %.2f A\n', min(id_a), max(id_a));
fprintf('  iq_ref min/max = %.2f / %.2f A\n', min(iq_r), max(iq_r));
fprintf('  iq_act min/max = %.2f / %.2f A\n', min(iq_a), max(iq_a));
