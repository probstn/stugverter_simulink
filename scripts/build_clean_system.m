% build_clean_system.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

% 1. Run motor and controller scripts
run('motor.m');
run('controller.m');

% 2. Open all models
load_system('foc_system');
load_system('foc_controller');
load_system('foc_plant');
load_system('foc_speedcontroller');

% 3. Configure foc_system blocks
% Remove unwanted legacy blocks if they exist
try, delete_block('foc_system/Constant'); catch, end
try, delete_block('foc_system/Step'); catch, end
try, delete_block('foc_system/Bus Selector'); catch, end

% Ensure MTPA Control Reference block exists
if isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'MTPA Control Reference'))
    add_block('mcbcontrolslib/MTPA Control Reference', 'foc_system/MTPA Control Reference', ...
        'Position', [350, 100, 480, 180]);
end

% Ensure Gain blocks exist
if isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'rpm2rads'))
    add_block('simulink/Math Operations/Gain', 'foc_system/rpm2rads', ...
        'Gain', 'pi/30', 'Position', [140, 100, 180, 130]);
else
    set_param('foc_system/rpm2rads', 'Gain', 'pi/30');
end

if isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'rads2rpm'))
    if ~isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'Gain'))
        set_param('foc_system/Gain', 'Name', 'rads2rpm', 'Gain', '30/pi');
    else
        add_block('simulink/Math Operations/Gain', 'foc_system/rads2rpm', ...
            'Gain', '30/pi', 'Position', [750, 250, 790, 280]);
    end
else
    set_param('foc_system/rads2rpm', 'Gain', '30/pi');
end

% Ensure Scope2 exists for monitoring id_ref, iq_ref, and torque
if isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'Scope2'))
    add_block('simulink/Sinks/Scope', 'foc_system/Scope2', ...
        'NumInputPorts', '3', 'Position', [550, 30, 590, 80]);
end

% Configure MTPA block
mtpa_blk = 'foc_system/MTPA Control Reference';
set_param(mtpa_blk, ...
    'Ld', 'pmsm.Ld', ...
    'Lq', 'pmsm.Lq', ...
    'polePairs', 'pmsm.P', ...
    'Rs', 'pmsm.Rs', ...
    'FluxPM', 'pmsm.fl', ...
    'ilimit', 'pmsm.I_rated', ...
    'V_dc', 'pmsm.V_rated', ...
    'N_base', 'pmsm.N_base', ...
    'Units', 'SI Units', ...
    'Vdc_input_select', 'Specify via dialog', ...
    'MTPAiterator', 'on', ...
    'VariantSelect', 'Interior PMSM');

% Configure Step1 block in foc_system
set_param('foc_system/Step1', 'Time', '0.02', 'Before', '0', 'After', '8000');

% Configure Bus Selector1 in foc_system
set_param('foc_system/Bus Selector1', 'OutputSignals', 'speed');

% 4. Configure foc_speedcontroller
spd_pi = 'foc_speedcontroller/PI Controller';
set_param(spd_pi, ...
    'P', 'foc.Kp_spd', ...
    'I', 'foc.Ki_spd', ...
    'UpperSaturationLimit', 'pmsm.T_peak', ...
    'LowerSaturationLimit', '-pmsm.T_peak', ...
    'AntiWindupMode', 'clamping');

% 5. Configure foc_controller
set_param('foc_controller/Id Controller', ...
    'P', 'foc.Kp_d', ...
    'I', 'foc.Ki_d', ...
    'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)', ...
    'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)', ...
    'AntiWindupMode', 'clamping');

set_param('foc_controller/Iq Controller', ...
    'P', 'foc.Kp_q', ...
    'I', 'foc.Ki_q', ...
    'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)', ...
    'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)', ...
    'AntiWindupMode', 'clamping');

% 6. Configure foc_plant
set_param('foc_plant/Interior PMSM', ...
    'Ldq', 'pmsm.Ldq', ...
    'mechanical', 'pmsm.mechanical', ...
    'lambda_pm', 'pmsm.fl', ...
    'Ke', 'pmsm.Ke');

% 7. Reconnect foc_system cleanly
lines = get_param('foc_system', 'Lines');
for l = 1:length(lines)
    delete_line(lines(l).Handle);
end

% Wiring:
% Step1 (RPM) -> rpm2rads -> Model (foc_speedcontroller, port 1: set_speed)
add_line('foc_system', 'Step1/1', 'rpm2rads/1', 'autorouting', 'on');
add_line('foc_system', 'Step1/1', 'Scope/1', 'autorouting', 'on');
add_line('foc_system', 'rpm2rads/1', 'Model/1', 'autorouting', 'on');

% Model (foc_speedcontroller, port 1: Torque) -> MTPA Control Reference (port 1: Tref) & Scope2 (port 3)
add_line('foc_system', 'Model/1', 'MTPA Control Reference/1', 'autorouting', 'on');
add_line('foc_system', 'Model/1', 'Scope2/3', 'autorouting', 'on');

% MTPA Control Reference:
% Port 1 (idref) -> current_control (foc_controller, port 1: id_ref) & Scope2 (port 1)
% Port 2 (iqref) -> current_control (foc_controller, port 2: iq_ref) & Scope2 (port 2)
add_line('foc_system', 'MTPA Control Reference/1', 'current_control/1', 'autorouting', 'on');
add_line('foc_system', 'MTPA Control Reference/2', 'current_control/2', 'autorouting', 'on');
add_line('foc_system', 'MTPA Control Reference/1', 'Scope2/1', 'autorouting', 'on');
add_line('foc_system', 'MTPA Control Reference/2', 'Scope2/2', 'autorouting', 'on');

% current_control (foc_controller, port 1: duty) -> Unit Delay -> plant (foc_plant, port 1: duty)
add_line('foc_system', 'current_control/1', 'Unit Delay/1', 'autorouting', 'on');
add_line('foc_system', 'current_control/1', 'Scope1/1', 'autorouting', 'on');
add_line('foc_system', 'Unit Delay/1', 'plant/1', 'autorouting', 'on');

% plant (foc_plant, port 1: measurements) -> current_control (port 3: measurements) & Bus Selector1
add_line('foc_system', 'plant/1', 'current_control/3', 'autorouting', 'on');
add_line('foc_system', 'plant/1', 'Bus Selector1/1', 'autorouting', 'on');

% Bus Selector1 (port 1: speed) ->
%   Model (foc_speedcontroller, port 2: meas_speed)
%   MTPA Control Reference (port 2: wm)
%   rads2rpm -> Scope (port 2: actual speed RPM)
add_line('foc_system', 'Bus Selector1/1', 'Model/2', 'autorouting', 'on');
add_line('foc_system', 'Bus Selector1/1', 'MTPA Control Reference/2', 'autorouting', 'on');
add_line('foc_system', 'Bus Selector1/1', 'rads2rpm/1', 'autorouting', 'on');
add_line('foc_system', 'rads2rpm/1', 'Scope/2', 'autorouting', 'on');

% Solver settings
set_param('foc_system', 'Solver', 'VariableStepAuto', 'MaxStep', '1e-5');

% Save all models (submodels first, then root system)
save_system('foc_speedcontroller');
save_system('foc_controller');
save_system('foc_plant');
save_system('foc_system', 'SaveDirtyReferencedModels', 'on');

fprintf('All models successfully wired, configured, and saved!\n');
