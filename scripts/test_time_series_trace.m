% test_time_series_trace.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

run('test_unified_tuning.m');

spd_ts = logs.get('Speed_Meas').Values;
id_r_ts = logs.get('id_ref').Values;
iq_r_ts = logs.get('iq_ref').Values;
id_a_ts = logs.get('id_actual').Values;
iq_a_ts = logs.get('iq_actual').Values;
trq_ts = logs.get('SpeedCtrl_Out').Values;

fprintf('\nTime [ms] | Ref [RPM] | Spd [RPM] | Trq [Nm] | id_ref [A] | id_act [A] | iq_ref [A] | iq_act [A]\n');
fprintf('-------------------------------------------------------------------------------------------------\n');
for t_val = 0:0.005:0.10
    s_val = interp1(spd_ts.Time, spd_ts.Data*(30/pi), t_val);
    trq_val = interp1(trq_ts.Time, trq_ts.Data, t_val);
    id_r_val = interp1(id_r_ts.Time, id_r_ts.Data, t_val);
    id_a_val = interp1(id_a_ts.Time, id_a_ts.Data, t_val);
    iq_r_val = interp1(iq_r_ts.Time, iq_r_ts.Data, t_val);
    iq_a_val = interp1(iq_a_ts.Time, iq_a_ts.Data, t_val);
    ref_val = (t_val >= 0.02) * 6000;
    fprintf('%8.1f  | %9.0f | %9.1f | %8.2f | %10.2f | %10.2f | %10.2f | %10.2f\n', ...
        t_val*1000, ref_val, s_val, trq_val, id_r_val, id_a_val, iq_r_val, iq_a_val);
end
