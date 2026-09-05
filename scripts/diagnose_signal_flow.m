% diagnose_signal_flow.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('init.m');
load_system('foc_system');
load_system('foc_speedcontroller');
load_system('foc_controller');
load_system('foc_plant');

% Check Model block parameters in foc_system
mdl_blk = 'foc_system/Model';
fprintf('Model block ModelName: %s\n', get_param(mdl_blk, 'ModelName'));
fprintf('current_control block ModelName: %s\n', get_param('foc_system/current_control', 'ModelName'));
fprintf('plant block ModelName: %s\n', get_param('foc_system/plant', 'ModelName'));

% Check port connectivity of Model block (speed controller)
c = get_param(mdl_blk, 'PortConnectivity');
for i = 1:length(c)
    if ~isempty(c(i).SrcBlock)
        fprintf('  Model inport %d from %s (port %d)\n', i, get_param(c(i).SrcBlock, 'Name'), c(i).SrcPort+1);
    end
    if ~isempty(c(i).DstBlock)
        for d = 1:length(c(i).DstBlock)
            fprintf('  Model outport %d to %s (port %d)\n', i-2, get_param(c(i).DstBlock(d), 'Name'), c(i).DstPort(d)+1);
        end
    end
end

% Check port connectivity of MTPA Control Reference
c_mtpa = get_param('foc_system/MTPA Control Reference', 'PortConnectivity');
for i = 1:length(c_mtpa)
    if ~isempty(c_mtpa(i).SrcBlock)
        fprintf('  MTPA inport %d from %s (port %d)\n', i, get_param(c_mtpa(i).SrcBlock, 'Name'), c_mtpa(i).SrcPort+1);
    end
    if ~isempty(c_mtpa(i).DstBlock)
        for d = 1:length(c_mtpa(i).DstBlock)
            fprintf('  MTPA outport %d to %s (port %d)\n', i-2, get_param(c_mtpa(i).DstBlock(d), 'Name'), c_mtpa(i).DstPort(d)+1);
        end
    end
end

% Let's test foc_speedcontroller standalone: set_speed = 8000*pi/30, meas_speed = 0 -> what torque does it output?
h = 'test_spd_sa';
new_system(h); load_system(h);
add_block('simulink/Ports & Subsystems/Model', [h '/spd_ctrl'], 'ModelName', 'foc_speedcontroller');
add_block('simulink/Sources/Constant', [h '/set_spd'], 'Value', '8000*pi/30');
add_block('simulink/Sources/Constant', [h '/meas_spd'], 'Value', '0');
add_block('simulink/Sinks/To Workspace', [h '/trq_out'], 'VariableName', 'trq_out', 'SaveFormat', 'Timeseries');
add_line(h, 'set_spd/1', 'spd_ctrl/1');
add_line(h, 'meas_spd/1', 'spd_ctrl/2');
add_line(h, 'spd_ctrl/1', 'trq_out/1');
set_param(h, 'StopTime', '0.001');
out = sim(h);
fprintf('\nStandalone foc_speedcontroller torque output: %.2f Nm (Expected: %.2f Nm = T_peak)\n', ...
    out.trq_out.Data(end), pmsm.T_peak);
close_system(h, 0);
