% test_speed_filtering.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

% Motor parameters
pmsm.P        = 4;
pmsm.Rs       = 0.126;
pmsm.Ld       = 0.35e-3;
pmsm.Lq       = 0.55e-3;
pmsm.Ldq      = [pmsm.Ld, pmsm.Lq];
pmsm.Ke_data  = 0.296;
pmsm.J        = 0.33e-3;
pmsm.B        = 1e-4;
pmsm.V_rated  = 600;
pmsm.I_rated  = 86.0;
pmsm.T_peak   = 29.1;
pmsm.T_rated  = 11.1;
pmsm.N_base   = 13650;
pmsm.N_max    = 20000;
pmsm.fl       = 0.0604;
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [pmsm.J pmsm.B 0];

% Controller parameters
foc.Ts = 1/20e3;  % 20 kHz
foc.omega_c = single(2*pi * 500); % 500 Hz current loop
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm);

% Speed loop tuning
foc.wn_s = single(2*pi * 5); % 5 Hz speed loop bandwidth
foc.zeta_s = single(1.0);     % critically damped
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J / Kt);
foc.Ki_spd = single(pmsm.J * foc.wn_s^2 / Kt);

% Measurement bus
clear measurement elems;
elems(1) = Simulink.BusElement; elems(1).Name = 'MtrPos'; elems(1).Dimensions = 1; elems(1).DataType = 'double';
elems(2) = Simulink.BusElement; elems(2).Name = 'currents'; elems(2).Dimensions = 3; elems(2).DataType = 'double';
elems(3) = Simulink.BusElement; elems(3).Name = 'speed'; elems(3).Dimensions = 1; elems(3).DataType = 'double';
measurement = Simulink.Bus;
measurement.Elements = elems;

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
    'MTPAiterator', 'on', ...
    'VariantSelect', 'Interior PMSM');

% Configure Speed Controller: explicitly set SampleTime to foc.Ts
set_param('foc_speedcontroller/PI Controller', ...
    'SampleTime', 'foc.Ts', ...
    'P', 'foc.Kp_spd', ...
    'I', 'foc.Ki_spd', ...
    'UpperSaturationLimit', 'pmsm.T_peak', ...
    'LowerSaturationLimit', '-pmsm.T_peak');

% Configure Current Controller PIs
set_param('foc_controller/Id Controller', 'P', 'foc.Kp_d', 'I', 'foc.Ki_d');
set_param('foc_controller/Iq Controller', 'P', 'foc.Kp_q', 'I', 'foc.Ki_q');

% Configure Plant
set_param('foc_plant/Interior PMSM', 'Ldq', 'pmsm.Ldq', 'mechanical', 'pmsm.mechanical');

% Solver settings
set_param('foc_system', 'Solver', 'VariableStepAuto', 'MaxStep', '1e-5');

% Test small step: 0 -> 3000 RPM
set_param('foc_system/Step1', 'Time', '0.01', 'Before', '0', 'After', '3000');
set_param('foc_system', 'StopTime', '0.08');

fprintf('Testing 0 -> 3000 RPM step with SampleTime = foc.Ts on speed PI...\n');
out = sim('foc_system');
logs = out.logsout;
spd = logs.get('Speed_Meas').Values.Data * (30/pi);
t = logs.get('Speed_Meas').Values.Time;

fprintf('Speed at t=0.01s: %.1f RPM\n', interp1(t, spd, 0.01));
fprintf('Speed at t=0.02s: %.1f RPM\n', interp1(t, spd, 0.02));
fprintf('Speed at t=0.04s: %.1f RPM\n', interp1(t, spd, 0.04));
fprintf('Speed at t=0.06s: %.1f RPM\n', interp1(t, spd, 0.06));
fprintf('Speed at t=0.08s: %.1f RPM\n', interp1(t, spd, 0.08));
