% test_open_loop_vq.m
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
pmsm.V_rated  = 600;
pmsm.I_rated  = 86.0;
pmsm.fl       = 0.0604;
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);
pmsm.mechanical = [1e6 0 0]; % Locked rotor

load_system('foc_controller');
load_system('foc_plant');
set_param('foc_plant/Interior PMSM', 'Ldq', 'pmsm.Ldq', 'mechanical', 'pmsm.mechanical');

harness = 'test_open_loop_vq';
new_system(harness);
load_system(harness);

add_block('foc_controller/PWM Reference Generator', [harness '/pwm']);
add_block('foc_plant/Average-Value Inverter', [harness '/inv']);
add_block('foc_plant/Interior PMSM', [harness '/pmsm']);
add_block('foc_controller/Clarke Transform', [harness '/clarke']);
add_block('foc_controller/Park Transform', [harness '/park']);
add_block('foc_controller/Demux', [harness '/demux']);
add_block('simulink/Sources/Constant', [harness '/Valpha_pu'], 'Value', '0');
add_block('simulink/Sources/Constant', [harness '/Vbeta_pu'], 'Value', '10*sqrt(3)/pmsm.V_rated');
add_block('simulink/Sources/Constant', [harness '/Vdc'], 'Value', 'pmsm.V_rated');
add_block('simulink/Sources/Constant', [harness '/Tload'], 'Value', '0');
add_block('simulink/Sources/Constant', [harness '/sin_th'], 'Value', '0');
add_block('simulink/Sources/Constant', [harness '/cos_th'], 'Value', '1');
add_block('simulink/Sinks/To Workspace', [harness '/id_meas'], 'VariableName', 'id_out', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [harness '/iq_meas'], 'VariableName', 'iq_out', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [harness '/vabc'], 'VariableName', 'vabc_out', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [harness '/iabc'], 'VariableName', 'iabc_out', 'SaveFormat', 'Timeseries');

% Connect
add_line(harness, 'Valpha_pu/1', 'pwm/1');
add_line(harness, 'Vbeta_pu/1', 'pwm/2');
add_line(harness, 'pwm/1', 'inv/1');
add_line(harness, 'Vdc/1', 'inv/2');
add_line(harness, 'inv/1', 'vabc/1');
add_line(harness, 'Tload/1', 'pmsm/1');
add_line(harness, 'inv/1', 'pmsm/2');
add_line(harness, 'pmsm/2', 'iabc/1');
add_line(harness, 'pmsm/2', 'demux/1');
add_line(harness, 'demux/1', 'clarke/1');
add_line(harness, 'demux/2', 'clarke/2');
add_line(harness, 'clarke/1', 'park/1');
add_line(harness, 'clarke/2', 'park/2');
add_line(harness, 'sin_th/1', 'park/3');
add_line(harness, 'cos_th/1', 'park/4');
add_line(harness, 'park/1', 'id_meas/1');
add_line(harness, 'park/2', 'iq_meas/1');

set_param(harness, 'StopTime', '0.005', 'MaxStep', '1e-5');
out = sim(harness);

id = out.id_out.Data;
iq = out.iq_out.Data;
vabc = out.vabc_out.Data;
iabc = out.iabc_out.Data;

fprintf('Open loop Vq = 10 V applied:\n');
fprintf('  Vabc = [%.2f, %.2f, %.2f] V\n', vabc(end, :));
fprintf('  Iabc = [%.2f, %.2f, %.2f] A\n', iabc(end, :));
fprintf('  id_measured = %.2f A\n', id(end));
fprintf('  iq_measured = %.2f A\n', iq(end));

close_system(harness, 0);
