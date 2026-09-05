% inspect_controller_voltages.m
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
pmsm.mechanical = [1e6 0 0];

foc.Ts = 1/20e3;
foc.omega_c = single(2*pi * 200);
foc.Kp_d = single(pmsm.Ld * foc.omega_c);
foc.Ki_d = single(pmsm.Rs * foc.omega_c);
foc.Kp_q = single(pmsm.Lq * foc.omega_c);
foc.Ki_q = single(pmsm.Rs * foc.omega_c);

load_system('foc_controller');
load_system('foc_plant');

% Mark all internal signals in foc_controller for logging
lines = get_param('foc_controller', 'Lines');
for l = 1:length(lines)
    try
        set_param(lines(l).Handle, 'DataLogging', 'on');
    catch
    end
end

harness = 'test_voltages_harness';
new_system(harness);
load_system(harness);

add_block('simulink/Ports & Subsystems/Model', [harness '/controller'], 'ModelName', 'foc_controller', 'Position', [200, 100, 350, 200]);
add_block('simulink/Ports & Subsystems/Model', [harness '/plant'], 'ModelName', 'foc_plant', 'Position', [450, 100, 600, 200]);
add_block('simulink/Discrete/Unit Delay', [harness '/delay'], 'SampleTime', 'foc.Ts', 'Position', [380, 140, 410, 160]);
add_block('simulink/Sources/Constant', [harness '/id_ref'], 'Value', '0', 'Position', [50, 100, 100, 120]);
add_block('simulink/Sources/Step', [harness '/iq_ref'], 'Time', '0.002', 'Before', '0', 'After', '10', 'Position', [50, 140, 100, 160]);

add_line(harness, 'id_ref/1', 'controller/1');
add_line(harness, 'iq_ref/1', 'controller/2');
add_line(harness, 'controller/1', 'delay/1');
add_line(harness, 'delay/1', 'plant/1');
add_line(harness, 'plant/1', 'controller/3', 'autorouting', 'on');

set_param(harness, 'StopTime', '0.003', 'MaxStep', '1e-5');
out = sim(harness);

logs = out.logsout;
fprintf('Logged %d signals:\n', logs.numElements);
for i = 1:logs.numElements
    sig = logs{i};
    fprintf('  Signal %d: %s\n', i, sig.Name);
    t = sig.Values.Time;
    d = sig.Values.Data;
    idx2 = find(t >= 0.002, 1);
    idx25 = find(t >= 0.0025, 1);
    if ismatrix(d) && size(d,2) == 1
        fprintf('     t=2ms: %.4f | t=2.5ms: %.4f\n', d(idx2), d(idx25));
    end
end

close_system(harness, 0);
