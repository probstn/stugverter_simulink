% test_cur_step_debug.m
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

foc.Ts = 1/20e3;
% Let's test with moderate, safe gains:
foc.omega_c = single(2*pi * 200); % 200 Hz current loop bandwidth
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

load_system('foc_controller');
load_system('foc_plant');

set_param('foc_controller/Id Controller', 'P', 'foc.Kp_d', 'I', 'foc.Ki_d');
set_param('foc_controller/Iq Controller', 'P', 'foc.Kp_q', 'I', 'foc.Ki_q');
set_param('foc_plant/Interior PMSM', 'Ldq', 'pmsm.Ldq', 'mechanical', 'pmsm.mechanical');

harness = 'test_step_debug';
new_system(harness);
load_system(harness);

add_block('simulink/Ports & Subsystems/Model', [harness '/controller'], 'ModelName', 'foc_controller', 'Position', [200, 100, 350, 200]);
add_block('simulink/Ports & Subsystems/Model', [harness '/plant'], 'ModelName', 'foc_plant', 'Position', [450, 100, 600, 200]);
add_block('simulink/Discrete/Unit Delay', [harness '/delay'], 'SampleTime', 'foc.Ts', 'Position', [380, 140, 410, 160]);
add_block('simulink/Sources/Constant', [harness '/id_ref'], 'Value', '0', 'Position', [50, 100, 100, 120]);
add_block('simulink/Sources/Step', [harness '/iq_ref'], 'Time', '0.002', 'Before', '0', 'After', '10', 'Position', [50, 140, 100, 160]);

% Add To Workspace blocks for id_ref, iq_ref, and controller signals
add_block('simulink/Signal Routing/Bus Selector', [harness '/bus_sel'], 'OutputSignals', 'speed,currents,MtrPos', 'Position', [650, 100, 660, 200]);
add_block('simulink/Sinks/To Workspace', [harness '/to_ws_curr'], 'VariableName', 'curr_out', 'SaveFormat', 'Timeseries');

add_line(harness, 'id_ref/1', 'controller/1');
add_line(harness, 'iq_ref/1', 'controller/2');
add_line(harness, 'controller/1', 'delay/1');
add_line(harness, 'delay/1', 'plant/1');
add_line(harness, 'plant/1', 'controller/3', 'autorouting', 'on');
add_line(harness, 'plant/1', 'bus_sel/1');
add_line(harness, 'bus_sel/2', 'to_ws_curr/1');

set_param(harness, 'StopTime', '0.01', 'MaxStep', '1e-5');
out = sim(harness);

logs = out.logsout;
id_act = logs.get('id_actual').Values;
iq_act = logs.get('iq_actual').Values;

fprintf('\nWith omega_c = 200 Hz, locked rotor step response (iq_ref = 10 A):\n');
for t_val = 0:0.001:0.010
    id_v = interp1(id_act.Time, id_act.Data, t_val);
    iq_v = interp1(iq_act.Time, iq_act.Data, t_val);
    fprintf('  t=%5.1f ms: id_act = %6.2f A, iq_act = %6.2f A\n', t_val*1000, id_v, iq_v);
end

close_system(harness, 0);
