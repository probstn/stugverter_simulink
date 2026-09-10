%% refactor_algorithm_supervisor.m
% Refactors algorithm.slx Operating Mode Supervisor to 5 top-level states:
% IDLE, READY, RUN, FAULT, CALIBRATION.
% Connects active_mode to Torque Mode Active for MTPA reference selection.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(simulinkDir, 'scripts', 'init.m'));
modelPath = fullfile(simulinkDir, 'models', 'algorithm.slx');
load_system(modelPath);
model = 'algorithm';

%% 1. Ensure Has Stored Resolver Offset Constant exists at top-level
hasStoredBlock = [model '/Has Stored Resolver Offset'];
if getSimulinkBlockHandle(hasStoredBlock) <= 0
    add_block('simulink/Sources/Constant', hasStoredBlock, ...
        'Value', 'has_stored_resolver_offset', ...
        'OutDataTypeStr', 'boolean', ...
        'Position', [655 690 795 720]);
end

%% 2. Ensure Supervisor State Terminator exists at top-level
termPath = [model '/Supervisor State Terminator'];
if getSimulinkBlockHandle(termPath) <= 0
    add_block('simulink/Sinks/Terminator', termPath, ...
        'Position', [1095 600 1115 620]);
end

%% 3. Configure Operating Mode Supervisor Stateflow Chart
chartPath = [model '/Operating Mode Supervisor'];
rt = sfroot;
chart = rt.find('-isa', 'Stateflow.Chart', 'Path', chartPath);

% Disconnect and clear existing chart contents
disconnectBlock(chartPath);
delete(chart.find('-isa', 'Stateflow.Transition'));
delete(chart.find('-isa', 'Stateflow.Junction'));
delete(chart.find('-isa', 'Stateflow.State'));
delete(chart.find('-isa', 'Stateflow.Data'));

% Input definitions
inputDefs = { ...
    'mode_request',        'uint8'; ...
    'enable_request',      'boolean'; ...
    'calibration_request', 'uint8'; ...
    'fault_active',        'boolean'; ...
    'reset_fault',         'boolean'; ...
    'current_cal_done',    'boolean'; ...
    'resolver_cal_done',   'boolean'; ...
    'has_stored_angle',    'boolean'  ...
};

for k = 1:size(inputDefs, 1)
    d = Stateflow.Data(chart);
    d.Name = inputDefs{k, 1};
    d.Scope = 'Input';
    d.Port = k;
    d.DataType = inputDefs{k, 2};
    d.Props.Array.Size = '1';
end

% Output definitions
% Ports 1..6 match existing downstream destinations; Port 7 is supervisor_state enum
outputDefs = { ...
    'active_mode',            'uint8'; ...
    'pwm_enable',             'boolean'; ...
    'current_cal_enable',     'boolean'; ...
    'resolver_align_enable',  'boolean'; ...
    'resolver_sample_enable', 'boolean'; ...
    'fault_latched',          'boolean'; ...
    'supervisor_state',       'Enum: SupervisorState' ...
};

for k = 1:size(outputDefs, 1)
    d = Stateflow.Data(chart);
    d.Name = outputDefs{k, 1};
    d.Scope = 'Output';
    d.Port = k;
    d.DataType = outputDefs{k, 2};
    d.Props.Array.Size = '1';
end

% Local definitions
loc = Stateflow.Data(chart);
loc.Name = 'startup_current_cal_done';
loc.Scope = 'Local';
loc.DataType = 'boolean';
loc.Props.Array.Size = '1';
loc.Props.InitialValue = 'false';

loc = Stateflow.Data(chart);
loc.Name = 'cal_request_processed';
loc.Scope = 'Local';
loc.DataType = 'boolean';
loc.Props.Array.Size = '1';
loc.Props.InitialValue = 'false';

loc = Stateflow.Data(chart);
loc.Name = 'ticks';
loc.Scope = 'Local';
loc.DataType = 'uint32';
loc.Props.Array.Size = '1';
loc.Props.InitialValue = '0';

for localDef = { ...
        'do_current_cal', 'boolean', 'false'; ...
        'do_angle_cal', 'boolean', 'false'; ...
        'run_mode', 'uint8', '0'; ...
        'reenable_required', 'boolean', 'false'}.'
    loc = Stateflow.Data(chart);
    loc.Name = localDef{1};
    loc.Scope = 'Local';
    loc.DataType = localDef{2};
    loc.Props.Array.Size = '1';
    loc.Props.InitialValue = localDef{3};
end

%% 4. Build Top-Level States: IDLE, READY, RUN, FAULT, CALIBRATION
% 1. IDLE
sIdle = Stateflow.State(chart);
sIdle.Name = 'IDLE';
sIdle.Position = [100 80 180 90];
sIdle.LabelString = sprintf([ ...
    'IDLE\n' ...
    'entry:\n' ...
    '  supervisor_state = SupervisorState.IDLE;\n' ...
    '  active_mode = uint8(0);\n' ...
    '  pwm_enable = false;\n' ...
    '  current_cal_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  fault_latched = false;\n' ...
    'during:\n' ...
    '  if calibration_request == uint8(0)\n' ...
    '    cal_request_processed = false;\n' ...
    '  end']);

% 2. READY
sReady = Stateflow.State(chart);
sReady.Name = 'READY';
sReady.Position = [400 80 180 90];
sReady.LabelString = sprintf([ ...
    'READY\n' ...
    'entry:\n' ...
    '  supervisor_state = SupervisorState.READY;\n' ...
    '  active_mode = uint8(0);\n' ...
    '  pwm_enable = false;\n' ...
    '  current_cal_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  fault_latched = false;\n' ...
    'during:\n' ...
    '  if ~enable_request\n' ...
    '    reenable_required = false;\n' ...
    '  end\n' ...
    '  if calibration_request == uint8(0)\n' ...
    '    cal_request_processed = false;\n' ...
    '  end']);

% 3. RUN
sRun = Stateflow.State(chart);
sRun.Name = 'RUN';
sRun.Position = [700 80 200 90];
sRun.LabelString = sprintf([ ...
    'RUN\n' ...
    'entry:\n' ...
    '  supervisor_state = SupervisorState.RUN;\n' ...
    '  run_mode = mode_request;\n' ...
    '  active_mode = run_mode;\n' ...
    '  pwm_enable = true;\n' ...
    '  current_cal_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  fault_latched = false;\n' ...
    'during:\n' ...
    '  active_mode = run_mode;\n' ...
    '  if calibration_request == uint8(0)\n' ...
    '    cal_request_processed = false;\n' ...
    '  end']);

% 4. FAULT
sFault = Stateflow.State(chart);
sFault.Name = 'FAULT';
sFault.Position = [400 500 180 80];
sFault.LabelString = sprintf([ ...
    'FAULT\n' ...
    'entry:\n' ...
    '  supervisor_state = SupervisorState.FAULT;\n' ...
    '  active_mode = uint8(0);\n' ...
    '  pwm_enable = false;\n' ...
    '  current_cal_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  fault_latched = true;']);

% 5. CALIBRATION (Contains sub-states CURRENT_CAL, ANGLE_ALIGN, ANGLE_SAMPLE, CAL_DONE)
sCal = Stateflow.State(chart);
sCal.Name = 'CALIBRATION';
sCal.Position = [100 230 780 230];
sCal.LabelString = sprintf([ ...
    'CALIBRATION\n' ...
    'entry:\n' ...
    '  supervisor_state = SupervisorState.CALIBRATION;\n' ...
    '  active_mode = uint8(0);\n' ...
    '  pwm_enable = false;\n' ...
    '  current_cal_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  do_current_cal = ~startup_current_cal_done || calibration_request == uint8(1) || calibration_request == uint8(3);\n' ...
    '  do_angle_cal = ~has_stored_angle || calibration_request == uint8(2) || calibration_request == uint8(3);\n' ...
    '  fault_latched = false;']);

% Calibration Sub-states:
% Sub-state: CURRENT_CAL
sCurrCal = Stateflow.State(sCal);
sCurrCal.Name = 'CURRENT_CAL';
sCurrCal.Position = [120 270 140 65];
sCurrCal.LabelString = sprintf([ ...
    'CURRENT_CAL\n' ...
    'entry:\n' ...
    '  current_cal_enable = true;\n' ...
    '  pwm_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    'exit:\n' ...
    '  current_cal_enable = false;\n' ...
    '  startup_current_cal_done = true;']);

% Sub-state: ANGLE_ALIGN
sAlign = Stateflow.State(sCal);
sAlign.Name = 'ANGLE_ALIGN';
sAlign.Position = [310 270 150 65];
sAlign.LabelString = sprintf([ ...
    'ANGLE_ALIGN\n' ...
    'entry:\n' ...
    '  current_cal_enable = false;\n' ...
    '  pwm_enable = true;\n' ...
    '  resolver_align_enable = true;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  ticks = uint32(0);\n' ...
    'during:\n' ...
    '  ticks = ticks + uint32(1);']);

% Sub-state: ANGLE_SAMPLE
sSample = Stateflow.State(sCal);
sSample.Name = 'ANGLE_SAMPLE';
sSample.Position = [500 270 150 65];
sSample.LabelString = sprintf([ ...
    'ANGLE_SAMPLE\n' ...
    'entry:\n' ...
    '  current_cal_enable = false;\n' ...
    '  pwm_enable = true;\n' ...
    '  resolver_align_enable = true;\n' ...
    '  resolver_sample_enable = true;']);

% Sub-state: CAL_DONE
sCalDone = Stateflow.State(sCal);
sCalDone.Name = 'CAL_DONE';
sCalDone.Position = [690 270 110 65];
sCalDone.LabelString = sprintf([ ...
    'CAL_DONE\n' ...
    'entry:\n' ...
    '  current_cal_enable = false;\n' ...
    '  pwm_enable = false;\n' ...
    '  resolver_align_enable = false;\n' ...
    '  resolver_sample_enable = false;\n' ...
    '  cal_request_processed = true;']);

%% 5. Internal Calibration Transitions (completely contained in CALIBRATION)
% A single unconditional default enters an explicit dispatcher state.
% Conditional branches from the dispatcher guarantee exactly one active child.
% Boot always requests current calibration through ~startup_current_cal_done;
% a missing stored angle additionally runs alignment.
sCalSelect = Stateflow.State(sCal);
sCalSelect.Name = 'SELECT_CALIBRATION';
sCalSelect.Position = [120 365 150 45];
sCalSelect.LabelString = sprintf([ ...
    'SELECT_CALIBRATION\n' ...
    'entry:\n' ...
    '  pwm_enable = false;']);
tdCal = Stateflow.Transition(sCal);
tdCal.Destination = sCalSelect;
tdCal.DestinationOClock = 9;

tStartCurrent = Stateflow.Transition(sCal);
tStartCurrent.Source = sCalSelect;
tStartCurrent.Destination = sCurrCal;
tStartCurrent.SourceOClock = 12;
tStartCurrent.DestinationOClock = 6;
tStartCurrent.LabelString = '[do_current_cal]';

tStartAngle = Stateflow.Transition(sCal);
tStartAngle.Source = sCalSelect;
tStartAngle.Destination = sAlign;
tStartAngle.SourceOClock = 3;
tStartAngle.DestinationOClock = 6;
tStartAngle.LabelString = '[~do_current_cal && do_angle_cal]';

tStartDone = Stateflow.Transition(sCal);
tStartDone.Source = sCalSelect;
tStartDone.Destination = sCalDone;
tStartDone.SourceOClock = 3;
tStartDone.DestinationOClock = 6;
tStartDone.MidPoint = [650 390];
tStartDone.LabelString = '';

% From CURRENT_CAL to ANGLE_ALIGN (if angle cal requested or no stored value yet)
tCurrToAlign = Stateflow.Transition(sCal);
tCurrToAlign.Source = sCurrCal;
tCurrToAlign.Destination = sAlign;
tCurrToAlign.SourceOClock = 3;
tCurrToAlign.DestinationOClock = 9;
tCurrToAlign.LabelString = '[current_cal_done && do_angle_cal]';

% From CURRENT_CAL to CAL_DONE (if angle cal NOT needed)
tCurrToDone = Stateflow.Transition(sCal);
tCurrToDone.Source = sCurrCal;
tCurrToDone.Destination = sCalDone;
tCurrToDone.SourceOClock = 6;
tCurrToDone.DestinationOClock = 6;
tCurrToDone.MidPoint = [475 390]; % Kept inside sCal bounds [100 230 780 230] (y in 230..460)
tCurrToDone.LabelString = '[current_cal_done && ~do_angle_cal]';

% From ANGLE_ALIGN to ANGLE_SAMPLE
tAlignToSample = Stateflow.Transition(sCal);
tAlignToSample.Source = sAlign;
tAlignToSample.Destination = sSample;
tAlignToSample.SourceOClock = 3;
tAlignToSample.DestinationOClock = 9;
tAlignToSample.LabelString = '[ticks >= uint32(5000)]';

% From ANGLE_SAMPLE to CAL_DONE
tSampleToDone = Stateflow.Transition(sCal);
tSampleToDone.Source = sSample;
tSampleToDone.Destination = sCalDone;
tSampleToDone.SourceOClock = 3;
tSampleToDone.DestinationOClock = 9;
tSampleToDone.LabelString = '[resolver_cal_done]';

%% 6. Top-Level State Transitions
% Default transition to IDLE
td = Stateflow.Transition(chart);
td.Destination = sIdle;
td.DestinationOClock = 9;

% IDLE -> CALIBRATION (on startup or when calibration requested)
tIdleToCal = Stateflow.Transition(chart);
tIdleToCal.Source = sIdle;
tIdleToCal.Destination = sCal;
tIdleToCal.SourceOClock = 6;
tIdleToCal.DestinationOClock = 9;
tIdleToCal.LabelString = '[~startup_current_cal_done || (calibration_request ~= uint8(0) && ~cal_request_processed)]';

% IDLE -> READY (if calibrated and mode requested)
tIdleToReady = Stateflow.Transition(chart);
tIdleToReady.Source = sIdle;
tIdleToReady.Destination = sReady;
tIdleToReady.SourceOClock = 3;
tIdleToReady.DestinationOClock = 9;
tIdleToReady.LabelString = '[startup_current_cal_done && mode_request >= uint8(1) && mode_request <= uint8(3)]';

% READY -> RUN (when enabled and mode requested)
tReadyToRun = Stateflow.Transition(chart);
tReadyToRun.Source = sReady;
tReadyToRun.Destination = sRun;
tReadyToRun.SourceOClock = 3;
tReadyToRun.DestinationOClock = 9;
tReadyToRun.LabelString = '[enable_request && ~reenable_required && mode_request >= uint8(1) && mode_request <= uint8(3)]';

% RUN -> READY (when disabled)
tRunToReady = Stateflow.Transition(chart);
tRunToReady.Source = sRun;
tRunToReady.Destination = sReady;
tRunToReady.SourceOClock = 9;
tRunToReady.DestinationOClock = 3;
tRunToReady.LabelString = '[~enable_request || mode_request ~= run_mode]{reenable_required = enable_request;}';

% READY -> IDLE (when mode is 0)
tReadyToIdle = Stateflow.Transition(chart);
tReadyToIdle.Source = sReady;
tReadyToIdle.Destination = sIdle;
tReadyToIdle.SourceOClock = 9;
tReadyToIdle.DestinationOClock = 3;
tReadyToIdle.LabelString = '[mode_request == uint8(0)]';

% RUN -> IDLE (when mode is 0)
tRunToIdle = Stateflow.Transition(chart);
tRunToIdle.Source = sRun;
tRunToIdle.Destination = sIdle;
tRunToIdle.SourceOClock = 12;
tRunToIdle.DestinationOClock = 12;
tRunToIdle.LabelString = '[mode_request == uint8(0) || mode_request > uint8(3)]';

% READY -> CALIBRATION (when calibration requested)
tReadyToCal = Stateflow.Transition(chart);
tReadyToCal.Source = sReady;
tReadyToCal.Destination = sCal;
tReadyToCal.SourceOClock = 6;
tReadyToCal.DestinationOClock = 12;
tReadyToCal.LabelString = '[calibration_request ~= uint8(0) && ~cal_request_processed]';

% CALIBRATION -> READY (when calibration complete from CAL_DONE and mode requested)
tCalToReady = Stateflow.Transition(chart);
tCalToReady.Source = sCal;
tCalToReady.Destination = sReady;
tCalToReady.SourceOClock = 12;
tCalToReady.DestinationOClock = 6;
tCalToReady.LabelString = '[cal_request_processed && mode_request ~= uint8(0)]';

% CALIBRATION -> IDLE (when calibration complete from CAL_DONE and mode is 0)
tCalToIdle = Stateflow.Transition(chart);
tCalToIdle.Source = sCal;
tCalToIdle.Destination = sIdle;
tCalToIdle.SourceOClock = 9;
tCalToIdle.DestinationOClock = 6;
tCalToIdle.LabelString = '[cal_request_processed && mode_request == uint8(0)]';

% Fault transitions: from IDLE, READY, RUN, CALIBRATION to FAULT
for s = [sIdle, sReady, sRun, sCal]
    tFault = Stateflow.Transition(chart);
    tFault.Source = s;
    tFault.Destination = sFault;
    tFault.SourceOClock = 6;
    tFault.DestinationOClock = 12;
    tFault.LabelString = '[fault_active]';
end

% FAULT -> IDLE (on fault reset when fault cleared)
tFaultToIdle = Stateflow.Transition(chart);
tFaultToIdle.Source = sFault;
tFaultToIdle.Destination = sIdle;
tFaultToIdle.SourceOClock = 9;
tFaultToIdle.DestinationOClock = 6;
tFaultToIdle.LabelString = '[reset_fault && ~fault_active]';

%% 7. Wire Connections in algorithm.slx
% Inport connections to Operating Mode Supervisor:
safeAddLine(model, 'Requested Mode/1', 'Operating Mode Supervisor/1');
safeAddLine(model, 'Enable Command/1', 'Operating Mode Supervisor/2');
safeAddLine(model, 'Calibration Request/1', 'Operating Mode Supervisor/3');
safeAddLine(model, 'Protection Monitor/1', 'Operating Mode Supervisor/4');
safeAddLine(model, 'Fault Reset Command/1', 'Operating Mode Supervisor/5');
safeAddLine(model, 'Sensor Offset Calibration/3', 'Operating Mode Supervisor/6');
safeAddLine(model, 'Sensor Offset Calibration/4', 'Operating Mode Supervisor/7');
safeAddLine(model, 'Has Stored Resolver Offset/1', 'Operating Mode Supervisor/8');

% Outport connections from Operating Mode Supervisor:
% 1: active_mode -> Duty Command Arbitration/1 AND Torque Mode Active/1
safeAddLine(model, 'Operating Mode Supervisor/1', 'Duty Command Arbitration/1');
safeAddLine(model, 'Operating Mode Supervisor/1', 'Torque Mode Active/1');
% 2: pwm_enable -> Duty Command Arbitration/2
safeAddLine(model, 'Operating Mode Supervisor/2', 'Duty Command Arbitration/2');
% 3: current_cal_enable -> Sensor Offset Calibration/2
safeAddLine(model, 'Operating Mode Supervisor/3', 'Sensor Offset Calibration/2');
% 4: resolver_align_enable -> Duty Command Arbitration/4
safeAddLine(model, 'Operating Mode Supervisor/4', 'Duty Command Arbitration/4');
% 5: resolver_sample_enable -> Sensor Offset Calibration/3
safeAddLine(model, 'Operating Mode Supervisor/5', 'Sensor Offset Calibration/3');
% 6: fault_latched -> Fault Latched Status/1
safeAddLine(model, 'Operating Mode Supervisor/6', 'Fault Latched Status/1');
% 7: supervisor_state -> Supervisor State Terminator/1
safeAddLine(model, 'Operating Mode Supervisor/7', 'Supervisor State Terminator/1');

% Cleanly reconnect all remaining Duty Command Arbitration inports
disconnectBlock([model '/Duty Command Arbitration']);
safeAddLine(model, 'Operating Mode Supervisor/1', 'Duty Command Arbitration/1');
safeAddLine(model, 'Operating Mode Supervisor/2', 'Duty Command Arbitration/2');
safeAddLine(model, 'FOC Duty Vector/1', 'Duty Command Arbitration/3');
safeAddLine(model, 'Operating Mode Supervisor/4', 'Duty Command Arbitration/4');
safeAddLine(model, 'Calibration Voltage/1', 'Duty Command Arbitration/5');
safeAddLine(model, 'Open-loop Voltage/1', 'Duty Command Arbitration/6');
safeAddLine(model, 'Open-loop Frequency/1', 'Duty Command Arbitration/7');
safeAddLine(model, 'Duty Command Arbitration/1', 'PWM Duty Cycles/1');

%% 8. Verify Torque Mode Active and Speed or Torque Select
switchPath = [model '/Torque Command Select'];
if getSimulinkBlockHandle(switchPath) <= 0
    switchPath = [model '/Speed or Torque Select'];
end
set_param(switchPath, 'Criteria', 'u2 >= Threshold', 'Threshold', '0.5');

compPath = [model '/Torque Mode Active'];
set_param(compPath, 'const', '1', 'relop', '==');

%% 9. Save model
set_param(model, 'ZoomFactor', 'FitSystem');
save_system(model, modelPath);
close_system(model, 0);
fprintf('[+] Successfully refactored algorithm.slx with 5-state supervisor and clean wiring!\n');

%% Helper functions
function disconnectBlock(blockPath)
ports = get_param(blockPath, 'PortHandles');
groups = {'Inport','Outport','Enable','Trigger','Ifaction','Reset'};
for g = 1:numel(groups)
    if isfield(ports, groups{g})
        for p = reshape(ports.(groups{g}), 1, [])
            line = get_param(p, 'Line');
            if line > 0
                delete_line(line);
            end
        end
    end
end
end

function safeAddLine(system, source, destination)
dstBlock = extractBefore(destination, '/');
dstPort = str2double(extractAfter(destination, '/'));
dstHandles = get_param([system '/' dstBlock], 'PortHandles');
if dstPort <= numel(dstHandles.Inport)
    oldLine = get_param(dstHandles.Inport(dstPort), 'Line');
    if oldLine > 0, delete_line(oldLine); end
end
add_line(system, source, destination, 'autorouting', 'smart');
end
