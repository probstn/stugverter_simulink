%% log_subsystem1_vs.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');

sys = 'foc_system/MTPA Control Reference/Motor_System/Interior PMSM/MTPA_FW_iteratorSelection/no_iterators/fast_and_approximate/Subsystem1';
gt_blk = [sys, '/GreaterThan'];

% Let's see the line connected to GreaterThan
lh = get_param(gt_blk, 'LineHandles');
p1 = get_param(lh.Inport(1), 'SrcPortHandle');
p2 = get_param(lh.Inport(2), 'SrcPortHandle');

disp(['GreaterThan input 1 from: ', get_param(p1, 'Parent')]);
disp(['GreaterThan input 2 from: ', get_param(p2, 'Parent')]);

set_param('foc_system', 'StopTime', '0.40');
out = sim('foc_system');

% Check what the value of Vs and Constant are
we_val = (10500 * pi/30) * pmsm.P;
id_val = -18.97;
iq_val = 78.03;
Vs_calc = we_val * sqrt((pmsm.fl + pmsm.Ld * id_val)^2 + (pmsm.Lq * iq_val)^2);
Vmax_calc = pmsm.V_rated / sqrt(3);

fprintf('At 10,500 RPM, id = -18.97 A, iq = 78.03 A:\n');
fprintf('  Calculated Vs   = %.2f V\n', Vs_calc);
fprintf('  Inverter Vmax   = %.2f V\n', Vmax_calc);
fprintf('  Vs > Vmax check = %d\n', Vs_calc > Vmax_calc);
