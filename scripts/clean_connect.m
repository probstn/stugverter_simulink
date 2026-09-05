% clean_connect.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('init.m');
load_system('foc_system');
load_system('foc_controller');
load_system('foc_plant');
load_system('foc_speedcontroller');

% Delete all lines in foc_system
lines = get_param('foc_system', 'Lines');
for l = 1:length(lines)
    delete_line(lines(l).Handle);
end

% Get port handles
p_step    = get_param('foc_system/Step1', 'PortHandles');
p_rpm2rad = get_param('foc_system/rpm2rads', 'PortHandles');
p_rad2rpm = get_param('foc_system/rads2rpm', 'PortHandles');
p_spd_mdl = get_param('foc_system/Model', 'PortHandles');
p_mtpa    = get_param('foc_system/MTPA Control Reference', 'PortHandles');
p_cur_mdl = get_param('foc_system/current_control', 'PortHandles');
p_delay   = get_param('foc_system/Unit Delay', 'PortHandles');
p_plant   = get_param('foc_system/plant', 'PortHandles');
p_bus_sel = get_param('foc_system/Bus Selector1', 'PortHandles');
p_scope   = get_param('foc_system/Scope', 'PortHandles');
p_scope1  = get_param('foc_system/Scope1', 'PortHandles');
p_scope2  = get_param('foc_system/Scope2', 'PortHandles');

% 1. Step1 -> rpm2rads & Scope(1)
add_line('foc_system', p_step.Outport(1), p_rpm2rad.Inport(1), 'autorouting', 'smart');
add_line('foc_system', p_step.Outport(1), p_scope.Inport(1), 'autorouting', 'smart');

% 2. rpm2rads -> Model (foc_speedcontroller, inport 1: set_speed)
add_line('foc_system', p_rpm2rad.Outport(1), p_spd_mdl.Inport(1), 'autorouting', 'smart');

% 3. Model (foc_speedcontroller, outport 1: Torque) -> MTPA (inport 1: Tref) & Scope2(3)
add_line('foc_system', p_spd_mdl.Outport(1), p_mtpa.Inport(1), 'autorouting', 'smart');
add_line('foc_system', p_spd_mdl.Outport(1), p_scope2.Inport(3), 'autorouting', 'smart');

% 4. MTPA: Outport 1 (idref) -> current_control (inport 1: id_ref) & Scope2(1)
add_line('foc_system', p_mtpa.Outport(1), p_cur_mdl.Inport(1), 'autorouting', 'smart');
add_line('foc_system', p_mtpa.Outport(1), p_scope2.Inport(1), 'autorouting', 'smart');

% 5. MTPA: Outport 2 (iqref) -> current_control (inport 2: iq_ref) & Scope2(2)
add_line('foc_system', p_mtpa.Outport(2), p_cur_mdl.Inport(2), 'autorouting', 'smart');
add_line('foc_system', p_mtpa.Outport(2), p_scope2.Inport(2), 'autorouting', 'smart');

% 6. current_control: Outport 1 (duty) -> Unit Delay & Scope1(1)
add_line('foc_system', p_cur_mdl.Outport(1), p_delay.Inport(1), 'autorouting', 'smart');
add_line('foc_system', p_cur_mdl.Outport(1), p_scope1.Inport(1), 'autorouting', 'smart');

% 7. Unit Delay -> plant (inport 1: duty)
add_line('foc_system', p_delay.Outport(1), p_plant.Inport(1), 'autorouting', 'smart');

% 8. plant: Outport 1 (measurements) -> current_control (inport 3: measurements) & Bus Selector1
add_line('foc_system', p_plant.Outport(1), p_cur_mdl.Inport(3), 'autorouting', 'smart');
add_line('foc_system', p_plant.Outport(1), p_bus_sel.Inport(1), 'autorouting', 'smart');

% 9. Bus Selector1: Outport 1 (speed) ->
%      Model (foc_speedcontroller, inport 2: meas_speed)
%      MTPA (inport 2: wm)
%      rads2rpm -> Scope(2)
add_line('foc_system', p_bus_sel.Outport(1), p_spd_mdl.Inport(2), 'autorouting', 'smart');
add_line('foc_system', p_bus_sel.Outport(1), p_mtpa.Inport(2), 'autorouting', 'smart');
add_line('foc_system', p_bus_sel.Outport(1), p_rad2rpm.Inport(1), 'autorouting', 'smart');
add_line('foc_system', p_rad2rpm.Outport(1), p_scope.Inport(2), 'autorouting', 'smart');

% Setup Signal Logging on Port Handles
set_param(p_step.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'spd_ref_rpm');
set_param(p_bus_sel.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'spd_meas_rads');
set_param(p_spd_mdl.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'Torque_cmd');
set_param(p_mtpa.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'id_ref');
set_param(p_mtpa.Outport(2), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'iq_ref');

% Save models
save_system('foc_speedcontroller');
save_system('foc_controller');
save_system('foc_plant');
save_system('foc_system', 'SaveDirtyReferencedModels', 'on');

fprintf('Clean port-based connection complete!\n');
