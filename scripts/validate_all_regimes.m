% validate_all_regimes.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('verify_clean_setup.m');

fprintf('\n================== TEST 1: MTPA REGIME (0 -> 8,000 RPM) ==================\n');
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '8000');
set_param('foc_system', 'StopTime', '0.12');
out1 = sim('foc_system');

logs1 = out1.logsout;
spd1 = logs1.get('Speed_Meas').Values.Data * (30/pi);
id_r1 = logs1.get('id_ref').Values.Data;
iq_r1 = logs1.get('iq_ref').Values.Data;
id_a1 = logs1.get('id_actual').Values.Data;
iq_a1 = logs1.get('iq_actual').Values.Data;
t1 = logs1.get('Speed_Meas').Values.Time;

fprintf('Final speed at t=0.12s: %.1f RPM (Target: 8000 RPM)\n', spd1(end));
fprintf('Max speed reached: %.1f RPM\n', max(spd1));
fprintf('id_ref min/max: %.2f / %.2f A (Reluctance torque MTPA id < 0 active!)\n', min(id_r1), max(id_r1));
fprintf('iq_ref min/max: %.2f / %.2f A\n', min(iq_r1), max(iq_r1));
fprintf('id_act min/max: %.2f / %.2f A\n', min(id_a1), max(id_a1));
fprintf('iq_act min/max: %.2f / %.2f A\n', min(iq_a1), max(iq_a1));

fprintf('\n================== TEST 2: FIELD WEAKENING REGIME (0 -> 18,000 RPM) ==================\n');
% Base speed is 13,650 RPM. Target 18,000 RPM is deep in the field weakening region.
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '18000');
set_param('foc_system', 'StopTime', '0.20');
out2 = sim('foc_system');

logs2 = out2.logsout;
spd2 = logs2.get('Speed_Meas').Values.Data * (30/pi);
id_r2 = logs2.get('id_ref').Values.Data;
iq_r2 = logs2.get('iq_ref').Values.Data;
id_a2 = logs2.get('id_actual').Values.Data;
iq_a2 = logs2.get('iq_actual').Values.Data;
t2 = logs2.get('Speed_Meas').Values.Time;

fprintf('Final speed at t=0.20s: %.1f RPM (Target: 18000 RPM)\n', spd2(end));
fprintf('Max speed reached: %.1f RPM\n', max(spd2));
fprintf('id_ref min/max: %.2f / %.2f A (Field weakening id < 0 active!)\n', min(id_r2), max(id_r2));
fprintf('iq_ref min/max: %.2f / %.2f A\n', min(iq_r2), max(iq_r2));
fprintf('id_act min/max: %.2f / %.2f A\n', min(id_a2), max(id_a2));
fprintf('iq_act min/max: %.2f / %.2f A\n', min(iq_a2), max(iq_a2));
