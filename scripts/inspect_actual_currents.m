% inspect_actual_currents.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

% Run test_fixes setup
run('test_fixes.m');

% Print sampled trajectory
t = logs.get('Speed_Meas').Values.Time;
spd = logs.get('Speed_Meas').Values.Data * (30/pi);
id_r = logs.get('id_ref').Values.Data;
iq_r = logs.get('iq_ref').Values.Data;
id_a = logs.get('id_actual').Values.Data;
iq_a = logs.get('iq_actual').Values.Data;
trq_cmd = logs.get('SpeedCtrl_Out').Values.Data;

fprintf('\nTime [ms] | Spd [RPM] | TrqCmd [Nm] | id_ref [A] | id_act [A] | iq_ref [A] | iq_act [A]\n');
fprintf('--------------------------------------------------------------------------------------\n');
sample_times = [0, 0.01, 0.02, 0.025, 0.03, 0.04, 0.05, 0.06, 0.08, 0.10];
for k = 1:length(sample_times)
    st = sample_times(k);
    idx = find(t >= st, 1);
    if ~isempty(idx)
        fprintf('%8.1f  | %9.1f | %11.2f | %10.2f | %10.2f | %10.2f | %10.2f\n', ...
            t(idx)*1000, spd(idx), trq_cmd(idx), id_r(idx), id_a(idx), iq_r(idx), iq_a(idx));
    end
end
