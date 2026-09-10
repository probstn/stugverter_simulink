%% build_monitor_dashboard.m
% Rebuild stugverter_monitor as a clean operator-facing dashboard. All XCP
% transport, command sources, conversion, logging, and decoding live inside
% one closed backend subsystem; the top level contains dashboard widgets only.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
modelFile = fullfile(simulinkDir, 'models', 'stugverter_monitor.slx');
modelName = 'stugverter_monitor';
load_system(modelFile);

backendName = 'Communications Backend';
backendPath = [modelName '/' backendName];

% Remove the previous operator layer completely.
widgetTypes = '(ToggleSwitchBlock|RotarySwitchBlock|ComboBox|ComboBoxBlock|PushButtonBlock|SliderBlock|CircularGaugeBlock|DashboardScope|DisplayBlock|LampBlock|EditFieldBlock)';
widgets = find_system(modelName, 'SearchDepth', 1, 'RegExp', 'on', 'BlockType', widgetTypes);
for k = 1:numel(widgets)
    delete_block(widgets{k});
end
notes = find_system(modelName, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'Annotation');
for k = 1:numel(notes)
    delete(notes(k));
end

if getSimulinkBlockHandle(backendPath) == -1
    % A single manual speed command is easier and safer than the old profile
    % override chain. The profile can still be exercised in SIL/HIL.
    stimPath = [modelName '/XCP UDP Data Stimulation'];
    stimPorts = get_param(stimPath, 'PortHandles');

    % Restore the calibration modulation source if an earlier dashboard
    % refactor left the STIM port without its authoritative constant.
    calModPath = [modelName '/Calibration Modulation'];
    if getSimulinkBlockHandle(calModPath) == -1
        add_block('simulink/Sources/Constant', calModPath, ...
            'Value', '0.005', 'OutDataTypeStr', 'double', ...
            'Position', [650 1015 780 1041]);
    end
    if get_param(stimPorts.Inport(10), 'Line') == -1
        add_line(modelName, 'Calibration Modulation/1', ...
            'XCP UDP Data Stimulation/10', 'autorouting', 'smart');
    end
    oldLine = get_param(stimPorts.Inport(2), 'Line');
    if oldLine ~= -1
        delete_line(oldLine);
    end
    add_line(modelName, 'Manual Speed/1', 'XCP UDP Data Stimulation/2', 'autorouting', 'smart');
    obsolete = {'Speed Source Select','Speed Profile','Speed Source Switch'};
    for k = 1:numel(obsolete)
        path = [modelName '/' obsolete{k}];
        if getSimulinkBlockHandle(path) ~= -1
            delete_block(path);
        end
    end

    % Group every implementation block. There are deliberately no external
    % ports: dashboard widgets bind wirelessly to blocks inside this subsystem.
    topBlocks = find_system(modelName, 'SearchDepth', 1, 'Type', 'Block');
    topBlocks = topBlocks(2:end);
    handles = cellfun(@getSimulinkBlockHandle, topBlocks);
    beforeSubsystems = find_system(modelName, 'SearchDepth', 1, 'BlockType', 'SubSystem');
    Simulink.BlockDiagram.createSubsystem(handles);
    afterSubsystems = find_system(modelName, 'SearchDepth', 1, 'BlockType', 'SubSystem');
    newSubsystem = setdiff(afterSubsystems, beforeSubsystems);
    assert(isscalar(newSubsystem), 'Could not identify the newly created backend subsystem.');
    backendHandle = getSimulinkBlockHandle(newSubsystem{1});
    set_param(backendHandle, 'Name', backendName, 'Position', [45 805 265 865], ...
        'BackgroundColor', 'lightBlue', 'ForegroundColor', 'blue');
end

daqPath = [backendPath '/XCP UDP Data Acquisition'];
speedGain = [backendPath '/Speed rad-s to RPM'];

% Dashboard observers can cause createSubsystem to generate unused boundary
% ports. The rebuilt dashboard binds directly to internal signals, so remove
% those empty pass-through ports and keep the backend icon port-free.
boundary = find_system(backendPath, 'SearchDepth', 1, 'RegExp', 'on', ...
    'BlockType', '(Inport|Outport)');
for k = 1:numel(boundary)
    delete_block(boundary{k});
end

% Keep calibration modulation explicitly inside the backend even when the
% subsystem API elects to leave a newly added source at the parent level.
backendCalMod = [backendPath '/Calibration Modulation'];
if getSimulinkBlockHandle(backendCalMod) == -1
    add_block('simulink/Sources/Constant', backendCalMod, ...
        'Value', '0.005', 'OutDataTypeStr', 'double', ...
        'Position', [650 1015 780 1041]);
    stimPorts = get_param([backendPath '/XCP UDP Data Stimulation'], 'PortHandles');
    oldLine = get_param(stimPorts.Inport(10), 'Line');
    if oldLine ~= -1
        delete_line(oldLine);
    end
    add_line(backendPath, 'Calibration Modulation/1', ...
        'XCP UDP Data Stimulation/10', 'autorouting', 'smart');
end
parentCalMod = [modelName '/Calibration Modulation'];
if getSimulinkBlockHandle(parentCalMod) ~= -1
    delete_block(parentCalMod);
end

% Make calibration an explicit momentary action. The dropdown chooses the
% procedure, while the push button pulses the chosen value. Releasing the
% button sends request 0 automatically, which rearms the target state machine.
calSelection = [backendPath '/Calibration Request'];
calExecute = [backendPath '/Execute Calibration'];
calCommand = [backendPath '/Calibration Command'];
if getSimulinkBlockHandle(calExecute) == -1
    add_block('simulink/Sources/Constant', calExecute, ...
        'Value', '0', 'OutDataTypeStr', 'double', ...
        'Position', [425 865 535 895]);
end
if getSimulinkBlockHandle(calCommand) == -1
    stimPorts = get_param([backendPath '/XCP UDP Data Stimulation'], 'PortHandles');
    oldLine = get_param(stimPorts.Inport(5), 'Line');
    if oldLine ~= -1
        delete_line(oldLine);
    end
    add_block('simulink/Math Operations/Product', calCommand, ...
        'Inputs', '**', 'Position', [585 820 625 875]);
    add_line(backendPath, 'Calibration Request/1', 'Calibration Command/1', ...
        'autorouting', 'smart');
    add_line(backendPath, 'Execute Calibration/1', 'Calibration Command/2', ...
        'autorouting', 'smart');
    add_line(backendPath, 'Calibration Command/1', ...
        'XCP UDP Data Stimulation/5', 'autorouting', 'smart');
end

% Ensure every commissioning value used by the dashboard is available.
selected = get_param(daqPath, 'SelectedMeasurements');
required = {'g_current_offset_u','g_current_offset_v','g_current_offset_w', ...
    'g_resolver_offset_runtime','g_adc_raw_curr_u','g_adc_raw_curr_v', ...
    'g_adc_raw_curr_w','g_adc_raw_res_sin','g_adc_raw_res_cos'};
for item = required
    if ~contains([';' selected ';'], [';' item{1} ';'])
        selected = [selected ';' item{1}]; %#ok<AGROW>
    end
end
set_param(daqPath, 'SelectedMeasurements', selected);
names = strsplit(selected, ';');
port = @(name) find(strcmp(names, name), 1);

% Conservative command defaults for the 20 V / 1 A supply-limited test.
set_param([backendPath '/Enable Request Value'], 'Value', '0');
set_param([backendPath '/Mode Request'], 'Value', '0');
set_param([backendPath '/Calibration Request'], 'Value', '0');
set_param([backendPath '/Execute Calibration'], 'Value', '0');
set_param([backendPath '/Fault Reset'], 'Value', '0');
set_param([backendPath '/Torque Reference'], 'Value', '0');
set_param([backendPath '/Manual Speed'], 'Value', '0');
set_param([backendPath '/Open Loop Hz'], 'Value', '0.5');
set_param([backendPath '/Open Loop Modulation'], 'Value', '0.001');
set_param([backendPath '/Calibration Modulation'], 'Value', '0.005');
set_param([backendPath '/Calibration Modulation'], 'OutDataTypeStr', 'double');

% Header and compact operating guidance.
note(modelName, 45, 30, 'STUGVERTER  |  20 V / 1 A COMMISSIONING', 21, 'bold', 'black');
note(modelName, 45, 65, 'CALIBRATE FIRST  →  choose one mode  →  set a low reference  →  ENABLE', 11, 'bold', '[0.05 0.35 0.70]');
note(modelName, 920, 35, 'SAFE DEFAULT', 11, 'bold', '[0.10 0.55 0.28]');
note(modelName, 920, 62, 'Mode OFF · Enable OFF · All references zero', 10, 'normal', '[0.30 0.35 0.40]');

% CONTROL card.
note(modelName, 45, 115, 'CONTROL', 14, 'bold', '[0.05 0.35 0.70]');
addParam('simulink_hmi_blocks/Toggle Switch', 'Enable', [50 165 115 230], ...
    [backendPath '/Enable Request Value'], []);
set_param([modelName '/Enable'], 'States', struct('Value', {0,1}, 'Label', {'OFF','ON'}));
addParam('simulink_hmi_blocks/Combo Box', 'Mode', [140 170 255 210], ...
    [backendPath '/Mode Request'], []);
set_param([modelName '/Mode'], 'States', struct('Value', {0,1,2,3}, ...
    'Label', {'OFF','TORQUE','SPEED','OPEN LOOP'}));
addParam('simulink_hmi_blocks/Toggle Switch', 'Fault Reset', [285 165 350 230], ...
    [backendPath '/Fault Reset'], []);
set_param([modelName '/Fault Reset'], 'States', struct('Value', {0,1}, 'Label', {'RELEASE','RESET'}));
note(modelName, 55, 145, 'MASTER ENABLE', 9, 'bold', 'black');
note(modelName, 140, 145, 'MODE', 9, 'bold', 'black');
note(modelName, 275, 145, 'FAULT RESET', 9, 'bold', 'black');
note(modelName, 145, 255, '0 OFF   1 TORQUE   2 SPEED   3 OPEN LOOP', 8, 'normal', '[0.35 0.35 0.35]');

addParam('simulink_hmi_blocks/Slider', 'Torque Reference', [50 315 335 365], ...
    [backendPath '/Torque Reference'], [-0.15 -1 0.15]);
addParam('simulink_hmi_blocks/Slider', 'Speed Reference', [50 415 335 465], ...
    [backendPath '/Manual Speed'], [0 -1 300]);
addParam('simulink_hmi_blocks/Slider', 'Open Loop Frequency', [50 515 180 565], ...
    [backendPath '/Open Loop Hz'], [0.2 -1 2.0]);
addParam('simulink_hmi_blocks/Slider', 'Open Loop Modulation', [205 515 335 565], ...
    [backendPath '/Open Loop Modulation'], [0.001 -1 0.010]);
note(modelName, 50, 290, 'TORQUE REFERENCE  [N·m]   ±0.15 max', 9, 'bold', 'black');
note(modelName, 50, 390, 'SPEED REFERENCE  [rpm]   300 max', 9, 'bold', 'black');
note(modelName, 50, 490, 'OPEN LOOP  [Hz]', 9, 'bold', 'black');
note(modelName, 205, 490, 'OPEN LOOP  [modulation]', 9, 'bold', 'black');

% CALIBRATION card.
note(modelName, 45, 610, 'CALIBRATION', 14, 'bold', '[0.05 0.35 0.70]');
addParam('simulink_hmi_blocks/Combo Box', 'Calibration Selection', [50 665 140 705], ...
    [backendPath '/Calibration Request'], []);
set_param([modelName '/Calibration Selection'], 'States', struct('Value', {0,1,2,3}, ...
    'Label', {'NONE','CURRENT','ANGLE','BOTH'}));
addParam('simulink_hmi_blocks/Push Button', 'Run Calibration', [155 665 335 705], ...
    [backendPath '/Execute Calibration'], []);
set_param([modelName '/Run Calibration'], 'ButtonText', 'RUN CALIBRATION', ...
    'ButtonType', 'Momentary', 'OnValue', '1');
addParam('simulink_hmi_blocks/Slider', 'Calibration Modulation', [50 735 335 775], ...
    [backendPath '/Calibration Modulation'], [0.002 -1 0.008]);
note(modelName, 50, 640, 'SELECTION', 9, 'bold', 'black');
note(modelName, 155, 640, 'EXECUTE', 9, 'bold', 'black');
note(modelName, 50, 715, 'ALIGNMENT MODULATION', 9, 'bold', 'black');
note(modelName, 50, 790, 'Button release automatically sends request NONE', 8, 'normal', '[0.35 0.35 0.35]');

% TELEMETRY card: the speed command and feedback are both RPM.
note(modelName, 390, 115, 'LIVE TELEMETRY', 14, 'bold', '[0.05 0.35 0.70]');
addSignal('simulink_hmi_blocks/Gauge', 'Rotor Speed', [395 150 555 295], speedGain, 1);
set_param([modelName '/Rotor Speed'], 'Limits', [0 -1 400]);
note(modelName, 430, 135, 'ROTOR SPEED  [rpm]', 9, 'bold', 'black');
addSignal('simulink_hmi_blocks/Display', 'Rotor Angle', [585 175 720 220], daqPath, port('g_meas_theta_mech'));
addSignal('simulink_hmi_blocks/Display', 'Resolver Offset', [585 250 720 295], daqPath, port('g_resolver_offset_runtime'));
note(modelName, 585, 150, 'ROTOR ANGLE  [rad]', 9, 'bold', 'black');
note(modelName, 585, 225, 'RESOLVER OFFSET  [rad]', 9, 'bold', 'black');

addScope('Speed Trend', [755 145 1100 295], ...
    {[backendPath '/Manual Speed'], 1; speedGain, 1}, [0 300]);
note(modelName, 755, 125, 'SPEED: command / measured  [rpm]', 9, 'bold', 'black');
addScope('Current Trend', [390 350 735 505], ...
    {daqPath, port('g_meas_curr_u'); daqPath, port('g_meas_curr_v'); daqPath, port('g_meas_curr_w')}, [-1 1]);
note(modelName, 390, 330, 'PHASE CURRENT  U / V / W  [A]', 9, 'bold', 'black');
addScope('Duty Trend', [755 350 1100 505], ...
    {daqPath, port('g_duty_u'); daqPath, port('g_duty_v'); daqPath, port('g_duty_w')}, [0 1]);
note(modelName, 755, 330, 'PWM DUTY  U / V / W', 9, 'bold', 'black');

% Learned calibration values.
note(modelName, 390, 550, 'LEARNED OFFSETS', 12, 'bold', '[0.05 0.35 0.70]');
offsetNames = {'U Offset','V Offset','W Offset'};
offsetSignals = {'g_current_offset_u','g_current_offset_v','g_current_offset_w'};
for k = 1:3
    x = 390 + (k-1)*120;
    addSignal('simulink_hmi_blocks/Display', offsetNames{k}, [x 595 x+105 640], ...
        daqPath, port(offsetSignals{k}));
    note(modelName, x, 575, sprintf('%s  [count]', offsetNames{k}(1)), 8, 'bold', 'black');
end
addSignal('simulink_hmi_blocks/Display', 'ISR Execution Time', [750 595 855 640], daqPath, port('g_foc_exec_time_us'));
note(modelName, 750, 575, 'ISR TIME  [µs]', 8, 'bold', 'black');

% STATUS card.
note(modelName, 1135, 115, 'STATUS & INTERLOCKS', 14, 'bold', '[0.05 0.35 0.70]');
addSignal('simulink_hmi_blocks/Display', 'Supervisor State', [1140 155 1265 200], daqPath, port('g_supervisor_state'));
addSignal('simulink_hmi_blocks/Display', 'Active Mode', [1140 230 1265 275], daqPath, port('g_supervisor_active_mode'));
addSignal('simulink_hmi_blocks/Display', 'Fault Word', [1140 305 1265 350], daqPath, port('g_fault_flags'));
note(modelName, 1140, 135, 'SUPERVISOR STATE', 8, 'bold', 'black');
note(modelName, 1140, 210, 'ACTIVE MODE', 8, 'bold', 'black');
note(modelName, 1140, 285, 'FAULT WORD', 8, 'bold', 'black');

green = [45 180 95];
red = [225 55 65];
addLamp('PWM Permission', [1140 390 1178 428], daqPath, port('g_supervisor_pwm_enable'), green);
addLamp('Gate Drivers', [1210 390 1248 428], daqPath, port('g_gate_drivers_enabled'), green);
addLamp('Calibration Done', [1280 390 1318 428], daqPath, port('g_calibration_complete'), green);
addLamp('Current Zero Done', [1140 470 1178 508], daqPath, port('g_startup_current_cal_done'), green);
addLamp('Stored Angle', [1210 470 1248 508], daqPath, port('has_stored_resolver_offset'), green);
note(modelName, 1135, 435, 'PWM', 8, 'bold', 'black');
note(modelName, 1200, 435, 'GATES', 8, 'bold', 'black');
note(modelName, 1270, 435, 'CAL DONE', 8, 'bold', 'black');
note(modelName, 1125, 515, 'I-ZERO', 8, 'bold', 'black');
note(modelName, 1195, 515, 'ANGLE', 8, 'bold', 'black');

decoder = [backendPath '/Fault Bit Decoder'];
faultNames = {'IU','IV','IW','SPEED','ADC LO','ADC HI','RES LO','RES HI','TRIP','XCP'};
for k = 1:numel(faultNames)
    row = floor((k-1)/2);
    col = mod(k-1, 2);
    x = 1140 + col*100;
    y = 565 + row*50;
    addLamp(['Fault ' faultNames{k}], [x y x+32 y+32], decoder, k, red);
    note(modelName, x+38, y+8, faultNames{k}, 8, 'bold', 'black');
end

note(modelName, 390, 700, 'ENERGIZED TEST ORDER', 11, 'bold', '[0.78 0.12 0.15]');
note(modelName, 390, 730, '1 Current zero (gates stay off)   2 Angle zero   3 Open loop ≤1 Hz / 0.001   4 Torque ≤0.05 N·m   5 Speed ≤100 rpm', 9, 'normal', '[0.30 0.35 0.40]');
note(modelName, 390, 758, 'Change mode only while ENABLE is OFF. Any red lamp: disable first, investigate, then reset.', 9, 'bold', '[0.78 0.12 0.15]');

set_param(backendPath, 'OpenFcn', 'open_system(gcb);');
set_param(modelName, 'ScreenColor', 'white');
open_system(modelName);
set_param(modelName, 'Location', [25 25 1510 930], 'ZoomFactor', '100', 'ScrollbarOffset', [0 0]);
save_system(modelName, modelFile);
close_system(modelName, 0);
fprintf('[OK] Rebuilt clean hardware monitor: %s\n', modelFile);

function addParam(library, name, position, source, limits)
modelName = 'stugverter_monitor';
path = [modelName '/' name];
add_block(library, path, 'Position', position, 'ShowName', 'off', 'LabelPosition', 'Hide');
binding = Simulink.HMI.ParamSourceInfo;
binding.BlockPath = Simulink.BlockPath(source);
binding.ParamName = 'Value';
set_param(path, 'Binding', binding);
if ~isempty(limits)
    set_param(path, 'Limits', limits);
end
end

function addSignal(library, name, position, source, outputPort)
modelName = 'stugverter_monitor';
path = [modelName '/' name];
add_block(library, path, 'Position', position, 'ShowName', 'off', 'LabelPosition', 'Hide');
binding = Simulink.HMI.SignalSpecification;
binding.BlockPath = Simulink.BlockPath(source);
binding.OutputPortIndex = outputPort;
set_param(path, 'Binding', binding);
end

function addScope(name, position, sources, ylimits)
modelName = 'stugverter_monitor';
path = [modelName '/' name];
add_block('simulink_hmi_blocks/Dashboard Scope', path, ...
    'Position', position, 'ShowName', 'off', 'LabelPosition', 'Hide');
bindings = cell(size(sources, 1), 1);
for k = 1:size(sources, 1)
    spec = Simulink.HMI.SignalSpecification;
    spec.BlockPath = Simulink.BlockPath(sources{k, 1});
    spec.OutputPortIndex = sources{k, 2};
    bindings{k} = spec;
end
set_param(path, 'Binding', bindings);
set_param(path, 'YLimits', ylimits, 'TimeSpan', '10');
end

function addLamp(name, position, source, outputPort, color)
addSignal('simulink_hmi_blocks/Lamp', name, position, source, outputPort);
set_param(['stugverter_monitor/' name], 'States', {0, color});
end

function h = note(modelName, x, y, text, fontSize, fontWeight, color)
h = Simulink.Annotation(modelName, text);
h.Position = [x y];
h.FontSize = fontSize;
h.FontWeight = fontWeight;
h.ForegroundColor = color;
h.Interpreter = 'off';
end
