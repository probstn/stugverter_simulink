% test_ramped_fw_reference.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

% 1. Clean IPMSM Parameters
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
pmsm.N_max    = 20000;      % Maximum speed [rpm]

pmsm.fl       = 0.0604;     % PM flux linkage [Wb]
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [pmsm.J pmsm.B 0];

% 2. Controller Gains
foc.Ts = 1/20e3;  % 20 kHz current control loop
foc.omega_c = single(2*pi * 600); % 600 Hz current loop bandwidth
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

lambda_pm = single(pmsm.fl);
Kt = single(1.5 * pmsm.P * lambda_pm);

% Speed loop tuning (10 Hz bandwidth, damping = 1.2)
foc.wn_s = single(2*pi * 10);
foc.zeta_s = single(1.2);
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

% 1. Configure MTPA block
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

% 2. Configure Speed Controller
set_param('foc_speedcontroller/PI Controller', ...
    'P', 'foc.Kp_spd', ...
    'I', 'foc.Ki_spd', ...
    'UpperSaturationLimit', 'pmsm.T_peak', ...
    'LowerSaturationLimit', '-pmsm.T_peak');

% 3. Configure Current Controllers
set_param('foc_controller/Id Controller', ...
    'P', 'foc.Kp_d', ...
    'I', 'foc.Ki_d', ...
    'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)', ...
    'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)');
set_param('foc_controller/Iq Controller', ...
    'P', 'foc.Kp_q', ...
    'I', 'foc.Ki_q', ...
    'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)', ...
    'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)');

% 4. Configure Plant
set_param('foc_plant/Interior PMSM', ...
    'Ldq', 'pmsm.Ldq', ...
    'mechanical', 'pmsm.mechanical');

% Solver settings
set_param('foc_system', 'Solver', 'VariableStepAuto', 'MaxStep', '1e-5');

% Replace Step1 in foc_system with a From Workspace block connected to sp_ts
% Let's create sp_ts with smooth ramp profile:
% 0 -> 8000 RPM (MTPA) in 40 ms -> hold 8000 RPM -> ramp to 18000 RPM (FW) in 50 ms -> hold 18000 RPM
t_prof   = [0, 0.01, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30];
spd_prof = [0,    0, 8000, 8000, 18000, 18000, 6000, 6000];
sp_ts = timeseries(spd_prof, t_prof);

% In foc_system, replace Step1 with From Workspace
try
    delete_block('foc_system/Step1');
    add_block('simulink/Sources/From Workspace', 'foc_system/sp_ts_block', ...
        'VariableName', 'sp_ts', 'Position', [100, 100, 180, 130]);
    add_line('foc_system', 'sp_ts_block/1', 'Gain1/1', 'autorouting', 'on');
    add_line('foc_system', 'sp_ts_block/1', 'Scope/1', 'autorouting', 'on');
catch
end

set_param('foc_system', 'StopTime', '0.30');
fprintf('Simulating full ramp profile (0 -> 8,000 RPM -> 18,000 RPM -> 6,000 RPM)...\n');
out = sim('foc_system');

logs = out.logsout;
spd_ts_out = logs.get('Speed_Meas').Values;
t = spd_ts_out.Time;
spd = spd_ts_out.Data * (30/pi);
id_r = logs.get('id_ref').Values.Data;
iq_r = logs.get('iq_ref').Values.Data;
id_a = logs.get('id_actual').Values.Data;
iq_a = logs.get('iq_actual').Values.Data;

fprintf('\nSummary of Ramped Simulation Results:\n');
fprintf('  Max Speed Reached: %.1f RPM\n', max(spd));
for t_check = [0.01, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30]
    ref_check = interp1(t_prof, spd_prof, t_check);
    spd_check = interp1(t, spd, t_check);
    id_r_check = interp1(t, id_r, t_check);
    id_a_check = interp1(t, id_a, t_check);
    iq_r_check = interp1(t, iq_r, t_check);
    iq_a_check = interp1(t, iq_a, t_check);
    fprintf('  t=%5.2fs | Ref=%5.0f RPM | Act=%7.1f RPM | id_ref=%6.2f A, id_act=%6.2f A | iq_ref=%6.2f A, iq_act=%6.2f A\n', ...
        t_check, ref_check, spd_check, id_r_check, id_a_check, iq_r_check, iq_a_check);
end
