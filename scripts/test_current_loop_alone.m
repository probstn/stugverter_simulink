% test_current_loop_alone.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

% IPMSM parameters
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
pmsm.mechanical = [pmsm.J 0 0];

foc.Ts = 1/20e3;
foc.omega_c = single(2*pi * 500);
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

load_system('foc_controller');
load_system('foc_plant');

% Set controller gains
set_param('foc_controller/Id Controller', 'P', 'foc.Kp_d', 'I', 'foc.Ki_d');
set_param('foc_controller/Iq Controller', 'P', 'foc.Kp_q', 'I', 'foc.Ki_q');
set_param('foc_plant/Interior PMSM', 'Ldq', 'pmsm.Ldq');

% Let's create a temporary harness to test foc_controller + foc_plant directly
harness = 'test_cur_harness';
new_system(harness);
load_system(harness);

% Add Model Reference for foc_controller and foc_plant
add_block('simulink/Ports & Subsystems/Model', [harness '/controller'], 'ModelName', 'foc_controller', 'Position', [200, 100, 350, 200]);
add_block('simulink/Ports & Subsystems/Model', [harness '/plant'], 'ModelName', 'foc_plant', 'Position', [450, 100, 600, 200]);
add_block('simulink/Discrete/Unit Delay', [harness '/delay'], 'SampleTime', 'foc.Ts', 'Position', [380, 140, 410, 160]);

% Constant id_ref = 0, Step iq_ref = 10 A
add_block('simulink/Sources/Constant', [harness '/id_ref'], 'Value', '0', 'Position', [50, 100, 100, 120]);
add_block('simulink/Sources/Step', [harness '/iq_ref'], 'Time', '0.005', 'Before', '0', 'After', '10', 'Position', [50, 140, 100, 160]);

% Bus Selector for currents, speed
add_block('simulink/Signal Routing/Bus Selector', [harness '/bus_sel'], 'OutputSignals', 'speed,currents,MtrPos', 'Position', [650, 100, 660, 200]);

% Add Scope / Outports
add_block('simulink/Sinks/To Workspace', [harness '/to_ws_spd'], 'VariableName', 'spd_out', 'SaveFormat', 'Timeseries', 'Position', [750, 80, 800, 100]);
add_block('simulink/Sinks/To Workspace', [harness '/to_ws_curr'], 'VariableName', 'curr_out', 'SaveFormat', 'Timeseries', 'Position', [750, 130, 800, 150]);

% Connect lines
add_line(harness, 'id_ref/1', 'controller/1');
add_line(harness, 'iq_ref/1', 'controller/2');
add_line(harness, 'controller/1', 'delay/1');
add_line(harness, 'delay/1', 'plant/1');
add_line(harness, 'plant/1', 'controller/3', 'autorouting', 'on');
add_line(harness, 'plant/1', 'bus_sel/1');
add_line(harness, 'bus_sel/1', 'to_ws_spd/1');
add_line(harness, 'bus_sel/2', 'to_ws_curr/1');

set_param(harness, 'StopTime', '0.02', 'MaxStep', '1e-5');
fprintf('Simulating current loop harness for 0.02s...\n');
out = sim(harness);

t = out.curr_out.Time;
curr = out.curr_out.Data;
spd = out.spd_out.Data * (30/pi);

fprintf('At t=0.004s: ia=%.2f, ib=%.2f, ic=%.2f, Spd=%.1f RPM\n', curr(find(t>=0.004,1),:), spd(find(t>=0.004,1)));
fprintf('At t=0.010s: ia=%.2f, ib=%.2f, ic=%.2f, Spd=%.1f RPM\n', curr(find(t>=0.010,1),:), spd(find(t>=0.010,1)));
fprintf('At t=0.020s: ia=%.2f, ib=%.2f, ic=%.2f, Spd=%.1f RPM\n', curr(find(t>=0.020,1),:), spd(find(t>=0.020,1)));

close_system(harness, 0);
