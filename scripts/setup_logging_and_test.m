% setup_logging_and_test.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('init.m');
load_system('foc_system');
load_system('foc_controller');

% 1. Mark signal logging on key ports in foc_system
p_spd_ref = get_param('foc_system/Step1', 'PortHandles');
set_param(p_spd_ref.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'spd_ref_rpm');

p_spd_meas = get_param('foc_system/Bus Selector1', 'PortHandles');
set_param(p_spd_meas.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'spd_meas_rads');

p_trq = get_param('foc_system/Model', 'PortHandles');
set_param(p_trq.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'Torque_cmd');

p_mtpa = get_param('foc_system/MTPA Control Reference', 'PortHandles');
set_param(p_mtpa.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'id_ref');
set_param(p_mtpa.Outport(2), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'iq_ref');

% 2. Mark signal logging on actual id and iq in foc_controller
p_park = get_param('foc_controller/Park Transform', 'PortHandles');
set_param(p_park.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'id_actual');
set_param(p_park.Outport(2), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'iq_actual');

% 3. Save models
save_system('foc_controller');
save_system('foc_system', 'SaveDirtyReferencedModels', 'on');

fprintf('Signal logging configured and models saved!\n');
