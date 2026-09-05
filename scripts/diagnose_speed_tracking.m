% diagnose_speed_tracking.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

% Configure IPMSM parameters
pmsm.P        = 4;
pmsm.Rs       = 0.126;
pmsm.Ld       = 0.35e-3;
pmsm.Lq       = 0.55e-3;
pmsm.Ldq      = [pmsm.Ld, pmsm.Lq];
pmsm.Ke_data  = 0.296;
pmsm.J        = 0.33e-3;
pmsm.V_rated  = 600;
pmsm.I_rated  = 86.0;
pmsm.T_peak   = 29.1;
pmsm.T_rated  = 11.1;
pmsm.N_base   = 13650;
pmsm.N_max    = 20000;
pmsm.fl       = 0.0604;
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [pmsm.J 0 0];

% Controller Gains
foc.Ts = 1/20e3;
foc.omega_c = single(2*pi * 1000); % Current loop bandwidth
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm);
foc.wn_s = single(2*pi * 10); % 10 Hz speed loop
foc.zeta_s = single(1.0);     % critically damped
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J / Kt);
foc.Ki_spd = single(pmsm.J * foc.wn_s^2 / Kt);

load_system('foc_system');
load_system('foc_controller');
load_system('foc_plant');
load_system('foc_speedcontroller');

% Set parameters in models
set_param('foc_system/MTPA Control Reference', ...
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

set_param('foc_speedcontroller/PI Controller', ...
    'P', 'foc.Kp_spd', ...
    'I', 'foc.Ki_spd', ...
    'UpperSaturationLimit', 'pmsm.T_peak', ...
    'LowerSaturationLimit', '-pmsm.T_peak');

set_param('foc_plant/Interior PMSM', 'Ldq', 'pmsm.Ldq');

% Test small speed step: 0 -> 1000 RPM for 0.05 s
set_param('foc_system/Step1', 'Time', '0.01', 'Before', '0', 'After', '1000');
set_param('foc_system', 'StopTime', '0.05');

out = sim('foc_system');
logs = out.logsout;
t = logs.get('Speed_Meas').Values.Time;
spd = logs.get('Speed_Meas').Values.Data * (30/pi);
id_r = logs.get('id_ref').Values.Data;
iq_r = logs.get('iq_ref').Values.Data;
id_a = logs.get('id_actual').Values.Data;
iq_a = logs.get('iq_actual').Values.Data;

fprintf('\nSmall step (1000 RPM) results:\n');
fprintf('  Speed at t=0.01s: %.1f RPM\n', interp1(t, spd, 0.01));
fprintf('  Speed at t=0.02s: %.1f RPM\n', interp1(t, spd, 0.02));
fprintf('  Speed at t=0.03s: %.1f RPM\n', interp1(t, spd, 0.03));
fprintf('  Speed at t=0.05s: %.1f RPM\n', interp1(t, spd, 0.05));
fprintf('  id_act at t=0.05s: %.2f A (id_ref: %.2f A)\n', interp1(t, id_a, 0.05), interp1(t, id_r, 0.05));
fprintf('  iq_act at t=0.05s: %.2f A (iq_ref: %.2f A)\n', interp1(t, iq_a, 0.05), interp1(t, iq_r, 0.05));
