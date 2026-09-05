% fix_speedcontroller_slx.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_speedcontroller');

% Remove legacy/unused blocks from foc_speedcontroller
legacy_blks = {'Constant', 'Constant1', 'Constant2', 'Constant3', 'Constant4', 'Constant5', ...
               'Display', 'Display1', 'FOC Default Controller Gains', 'From', 'From1', ...
               'Goto', 'Goto1', 'Terminator', 'Bus Selector', 'Id', 'Iq', 'Gain'};
for k = 1:length(legacy_blks)
    try
        delete_block(['foc_speedcontroller/' legacy_blks{k}]);
    catch
    end
end

% Delete existing lines in foc_speedcontroller
lines = get_param('foc_speedcontroller', 'Lines');
for l = 1:length(lines)
    delete_line(lines(l).Handle);
end

% Ensure Outport 'Torque' exists
if isempty(find_system('foc_speedcontroller', 'SearchDepth', 1, 'Name', 'Torque'))
    add_block('simulink/Sinks/Out1', 'foc_speedcontroller/Torque', ...
        'Port', '1', 'Position', [380, 100, 410, 120]);
end

% Configure Subtract block
set_param('foc_speedcontroller/Subtract', 'Inputs', '+-');

% Configure PI Controller block
spd_pi = 'foc_speedcontroller/PI Controller';
set_param(spd_pi, ...
    'Controller', 'PI', ...
    'TimeDomain', 'Discrete-time', ...
    'SampleTime', '-1', ...
    'IntegratorMethod', 'Forward Euler', ...
    'P', 'foc.Kp_spd', ...
    'I', 'foc.Ki_spd', ...
    'UpperSaturationLimit', 'pmsm.T_peak', ...
    'LowerSaturationLimit', '-pmsm.T_peak', ...
    'AntiWindupMode', 'clamping');

% Connect:
% set_speed -> Subtract port 1 (+)
% meas_speed -> Subtract port 2 (-)
% Subtract -> PI Controller -> Torque
p_set  = get_param('foc_speedcontroller/set_speed', 'PortHandles');
p_meas = get_param('foc_speedcontroller/meas_speed', 'PortHandles');
p_sub  = get_param('foc_speedcontroller/Subtract', 'PortHandles');
p_pi   = get_param('foc_speedcontroller/PI Controller', 'PortHandles');
p_trq  = get_param('foc_speedcontroller/Torque', 'PortHandles');

add_line('foc_speedcontroller', p_set.Outport(1), p_sub.Inport(1), 'autorouting', 'smart');
add_line('foc_speedcontroller', p_meas.Outport(1), p_sub.Inport(2), 'autorouting', 'smart');
add_line('foc_speedcontroller', p_sub.Outport(1), p_pi.Inport(1), 'autorouting', 'smart');
add_line('foc_speedcontroller', p_pi.Outport(1), p_trq.Inport(1), 'autorouting', 'smart');

save_system('foc_speedcontroller');
fprintf('foc_speedcontroller cleaned and saved successfully!\n');
