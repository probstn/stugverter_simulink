% test_mtpa_negative_torque.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

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

load_system('foc_system');

% Create test harness for MTPA block only
harness = 'test_mtpa_harness';
new_system(harness);
load_system(harness);

add_block('foc_system/MTPA Control Reference', [harness '/mtpa']);
add_block('simulink/Sources/Constant', [harness '/Tref'], 'Value', '-10');
add_block('simulink/Sources/Constant', [harness '/wm'], 'Value', '1000*pi/30');
add_block('simulink/Sinks/To Workspace', [harness '/id_ref'], 'VariableName', 'id_r', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [harness '/iq_ref'], 'VariableName', 'iq_r', 'SaveFormat', 'Timeseries');

add_line(harness, 'Tref/1', 'mtpa/1');
add_line(harness, 'wm/1', 'mtpa/2');
add_line(harness, 'mtpa/1', 'id_ref/1');
add_line(harness, 'mtpa/2', 'iq_ref/1');

set_param(harness, 'StopTime', '0.001');
out = sim(harness);

fprintf('MTPA with Tref = -10 Nm, wm = 1000 RPM:\n');
fprintf('  id_ref = %.2f A\n', out.id_r.Data(end));
fprintf('  iq_ref = %.2f A\n', out.iq_r.Data(end));

close_system(harness, 0);
