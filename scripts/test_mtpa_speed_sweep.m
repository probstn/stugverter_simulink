% test_mtpa_speed_sweep.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
mtpa_blk = 'foc_system/MTPA Control Reference';

% Let's test what MTPA block calculates across speeds at full torque Tref = 20 Nm
speeds_rpm = [1000, 5000, 8000, 10000, 12000, 14000, 16000, 18000, 20000];

h = 'test_sweep';
new_system(h); load_system(h);
add_block(mtpa_blk, [h '/mtpa']);
add_block('simulink/Sources/Constant', [h '/Tref'], 'Value', '20');
add_block('simulink/Sources/Constant', [h '/wm'], 'Value', '0');
add_block('simulink/Sinks/To Workspace', [h '/id_out'], 'VariableName', 'id_out', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [h '/iq_out'], 'VariableName', 'iq_out', 'SaveFormat', 'Timeseries');

add_line(h, 'Tref/1', 'mtpa/1');
add_line(h, 'wm/1', 'mtpa/2');
add_line(h, 'mtpa/1', 'id_out/1');
add_line(h, 'mtpa/2', 'iq_out/1');

fprintf('MTPA + Field Weakening Reference Current Map (Tref = 20 Nm):\n');
fprintf('  Speed [RPM] | Speed [rad/s] | id_ref [A] | iq_ref [A] | Is_mag [A] | Regime\n');
fprintf('----------------------------------------------------------------------------\n');

for i = 1:length(speeds_rpm)
    rpm_val = speeds_rpm(i);
    rads_val = rpm_val * pi / 30;
    set_param([h '/wm'], 'Value', num2str(rads_val));
    out = sim(h, 'StopTime', '0.001');
    id_v = out.id_out.Data(end);
    iq_v = out.iq_out.Data(end);
    Is_mag = sqrt(id_v^2 + iq_v^2);
    if rpm_val <= pmsm.N_base
        regime = 'MTPA';
    else
        regime = 'Field Weakening';
    end
    fprintf('  %10d  | %13.1f | %10.2f | %10.2f | %10.2f | %s\n', ...
        rpm_val, rads_val, id_v, iq_v, Is_mag, regime);
end

close_system(h, 0);
