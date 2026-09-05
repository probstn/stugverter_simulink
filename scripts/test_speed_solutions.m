% test_speed_solutions.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

% 1. Motor Parameters
pmsm.P        = 4;          % Pole pairs
pmsm.Rs       = 0.126;      % Phase resistance [Ohm]
pmsm.Ld       = 0.35e-3;    % d-axis Inductance [H]
pmsm.Lq       = 0.55e-3;    % q-axis Inductance [H] (Lq > Ld for IPMSM)
pmsm.Ldq      = [pmsm.Ld, pmsm.Lq];
pmsm.Ke_data  = 0.296;      % BEMF constant [Vrms_LL/(rad/s)]
pmsm.J        = 0.33e-3;    % Rotor inertia [kg*m^2]
pmsm.B        = 1e-4;       % Damping [Nm/(rad/s)]
pmsm.V_rated  = 600;        % DC bus voltage [V]
pmsm.I_rated  = 86.0;       % Peak phase current limit [A]
pmsm.T_peak   = 29.1;       % Peak torque [Nm]
pmsm.T_rated  = 11.1;       % Nominal torque [Nm]

% Base speed: Fischer datasheet specifies idle/no-load base speed ~13650 rpm.
% Under peak load current, voltage saturation begins around 9500-10000 rpm.
pmsm.N_base   = 9500;       % Operating base speed for Field Weakening entry [rpm]
pmsm.N_max    = 20000;      % Maximum speed with field weakening [rpm]

pmsm.fl       = 0.0604;     % PM flux linkage [Wb]
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [pmsm.J pmsm.B 0];

% 2. Controller Gains
foc.Ts = 1/20e3;  % 20 kHz current control loop
foc.omega_c = single(2*pi * 800); % 800 Hz bandwidth
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm);

% Speed loop tuning
foc.wn_s = single(2*pi * 15);
foc.zeta_s = single(1.0);
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J / Kt);
foc.Ki_spd = single(pmsm.J * foc.wn_s^2 / Kt);

% Update MTPA block with updated N_base
load_system('foc_system');
set_param('foc_system/MTPA Control Reference', ...
    'N_base', 'pmsm.N_base', ...
    'Ld', 'pmsm.Ld', ...
    'Lq', 'pmsm.Lq', ...
    'V_dc', 'pmsm.V_rated');

save_system('foc_system', 'SaveDirtyReferencedModels', 'on');

% Test 0 -> 18000 RPM with FW
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '18000');
set_param('foc_system', 'StopTime', '0.25');

fprintf('Running simulation to 18000 RPM with N_base = %d RPM...\n', pmsm.N_base);
out = sim('foc_system');
logs = out.logsout;
spd = logs.get('spd_meas_rads').Values.Data * (30/pi);
id_r = logs.get('id_ref').Values.Data;
iq_r = logs.get('iq_ref').Values.Data;
id_a = logs.get('id_actual').Values.Data;
iq_a = logs.get('iq_actual').Values.Data;
t = logs.get('spd_meas_rads').Values.Time;

fprintf('\nSimulation Results:\n');
fprintf('  Final Speed at t=0.25s: %.1f RPM (Target: 18000 RPM)\n', spd(end));
fprintf('  Max Speed Reached: %.1f RPM\n', max(spd));
fprintf('  id_ref min/max: %.2f / %.2f A (Deep field weakening active!)\n', min(id_r), max(id_r));
fprintf('  iq_ref min/max: %.2f / %.2f A\n', min(iq_r), max(iq_r));
fprintf('  id_act min/max: %.2f / %.2f A\n', min(id_a), max(id_a));
fprintf('  iq_act min/max: %.2f / %.2f A\n', min(iq_a), max(iq_a));
