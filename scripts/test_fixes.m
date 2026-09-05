% test_fixes.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

% 1. Set IPMSM parameters in motor.m & controller.m
pmsm.P        = 4;          % Pole pairs
pmsm.Rs       = 0.126;      % Phase resistance [Ohm]
pmsm.Ld       = 0.35e-3;    % d-axis Inductance [H]
pmsm.Lq       = 0.55e-3;    % q-axis Inductance [H] (Lq > Ld for IPMSM)
pmsm.Ldq      = [pmsm.Ld, pmsm.Lq];
pmsm.Ke_data  = 0.296;      % BEMF constant [Vrms_LL/(rad/s)]
pmsm.J        = 0.33e-3;    % Rotor inertia [kg*m^2]
pmsm.V_rated  = 600;        % DC bus voltage [V]
pmsm.I_rated  = 86.0;       % Peak phase current limit [A]
pmsm.T_peak   = 29.1;       % Peak torque [Nm]
pmsm.T_rated  = 11.1;       % Nominal torque [Nm]
pmsm.N_base   = 13650;      % Base speed [rpm]
pmsm.N_max    = 20000;      % Maximum speed with field weakening [rpm]

pmsm.fl       = 0.0604;     % PM flux linkage [Wb]
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [pmsm.J 0 0];

% Controller parameters
foc.Ts = 1/20e3;  % 20 kHz
foc.omega_c = single(2*pi * 1000);
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm);
foc.wn_s = single(2*pi * 20); % 20 Hz bandwidth for speed loop
foc.zeta_s = single(1.0);     % critically damped
foc.Kp_spd = single(2 * foc.zeta_s * foc.wn_s * pmsm.J / Kt);
foc.Ki_spd = single(pmsm.J * foc.wn_s^2 / Kt);

% Bus definitions
elems(1) = Simulink.BusElement; elems(1).Name = 'MtrPos'; elems(1).Dimensions = 1; elems(1).DataType = 'double';
elems(2) = Simulink.BusElement; elems(2).Name = 'currents'; elems(2).Dimensions = 3; elems(2).DataType = 'double';
elems(3) = Simulink.BusElement; elems(3).Name = 'speed'; elems(3).Dimensions = 1; elems(3).DataType = 'double';
measurement = Simulink.Bus;
measurement.Elements = elems;

% Configure models
load_system('foc_system');
load_system('foc_controller');
load_system('foc_plant');
load_system('foc_speedcontroller');

% 1. Configure MTPA block in foc_system
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

% 2. Configure foc_speedcontroller PI Controller
spd_pi = 'foc_speedcontroller/PI Controller';
set_param(spd_pi, 'P', 'foc.Kp_spd');
set_param(spd_pi, 'I', 'foc.Ki_spd');
set_param(spd_pi, 'UpperSaturationLimit', 'pmsm.T_peak');
set_param(spd_pi, 'LowerSaturationLimit', '-pmsm.T_peak');

% 3. Configure foc_plant Interior PMSM
plant_pmsm = 'foc_plant/Interior PMSM';
set_param(plant_pmsm, 'Ldq', 'pmsm.Ldq');

% 4. Test Step to 8000 RPM (MTPA region, below base speed of 13650 RPM)
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '8000');
set_param('foc_system', 'StopTime', '0.1');

fprintf('Testing MTPA regime (0 -> 8000 RPM)...\n');
out = sim('foc_system');
logs = out.logsout;
spd = logs.get('Speed_Meas').Values.Data * (30/pi);
id_ref = logs.get('id_ref').Values.Data;
iq_ref = logs.get('iq_ref').Values.Data;
id_act = logs.get('id_actual').Values.Data;
iq_act = logs.get('iq_actual').Values.Data;
t = logs.get('Speed_Meas').Values.Time;

fprintf('Final Speed: %.1f RPM\n', spd(end));
fprintf('id_ref min/max: %.2f / %.2f A\n', min(id_ref), max(id_ref));
fprintf('iq_ref min/max: %.2f / %.2f A\n', min(iq_ref), max(iq_ref));
fprintf('id_act min/max: %.2f / %.2f A\n', min(id_act), max(id_act));
fprintf('iq_act min/max: %.2f / %.2f A\n', min(iq_act), max(iq_act));

% 5. Test Step to 18000 RPM (Field Weakening region, above base speed of 13650 RPM)
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '18000');
set_param('foc_system', 'StopTime', '0.2');

fprintf('\nTesting Field Weakening regime (0 -> 18000 RPM)...\n');
out_fw = sim('foc_system');
logs_fw = out_fw.logsout;
spd_fw = logs_fw.get('Speed_Meas').Values.Data * (30/pi);
id_ref_fw = logs_fw.get('id_ref').Values.Data;
iq_ref_fw = logs_fw.get('iq_ref').Values.Data;
id_act_fw = logs_fw.get('id_actual').Values.Data;
iq_act_fw = logs_fw.get('iq_actual').Values.Data;

fprintf('Final Speed: %.1f RPM (Target: 18000 RPM)\n', spd_fw(end));
fprintf('id_ref min/max: %.2f / %.2f A\n', min(id_ref_fw), max(id_ref_fw));
fprintf('iq_ref min/max: %.2f / %.2f A\n', min(iq_ref_fw), max(iq_ref_fw));
fprintf('id_act min/max: %.2f / %.2f A\n', min(id_act_fw), max(id_act_fw));
fprintf('iq_act min/max: %.2f / %.2f A\n', min(iq_act_fw), max(iq_act_fw));
