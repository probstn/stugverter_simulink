%% configure_processor_logging.m
% One-time/idempotent layout migration for stugverter_sim.
% Keeps the SIL/HIL variant interface minimal (duty only) and records all
% comparable simulation signals once, outside the variant, in Processor.

model = 'stugverter_sim';
modelsDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'models');
modelFile = fullfile(modelsDir, [model '.slx']);
load_system(modelFile);

processor = [model '/Processor'];
variant   = [processor '/Controller Mode'];

% Hardware-only diagnostics belong to XCP/target monitoring, not to the
% common SIL/HIL simulation interface.  Consume that output locally.
hil = [variant '/HIL'];
safeDelete([hil '/telemetry']);
safeDelete([hil '/Target Telemetry']);
if isempty(find_system(hil, 'SearchDepth', 1, 'Name', 'Terminate XCP diagnostics'))
    add_block('simulink/Sinks/Terminator', [hil '/Terminate XCP diagnostics'], ...
        'Position', [485 218 505 238]);
end
safeLine(hil, 'XCP HIL/2', 'Terminate XCP diagnostics/1');

sil = [variant '/SIL'];
safeDelete([sil '/telemetry']);
safeDelete([sil '/No Hardware Telemetry']);
safeDelete([variant '/telemetry']);

% Make the selected implementation obvious without exposing two parallel
% controller blocks.  The icon displays the value that selects the choice.
set_param(variant, 'AttributesFormatString', ...
    'simulation_mode = %<simulation_mode>\n0: SIL   |   1: HIL (XCP/UDP)');

logging = [processor '/Logging'];
safeDelete(logging);
add_block('simulink/Ports & Subsystems/Subsystem', logging, ...
    'Position', [555 245 735 375]);

% Build the logging subsystem from explicit interfaces.  It is downstream
% of the controller selection, so its contents and variable names are
% identical for SIL and HIL.
add_block('simulink/Sources/In1', [logging '/speed_ref_rpm'], ...
    'Port', '1', 'Position', [25 35 55 49]);
add_block('simulink/Sources/In1', [logging '/measurements'], ...
    'Port', '2', 'Position', [25 92 55 106]);
add_block('simulink/Sources/In1', [logging '/duty'], ...
    'Port', '3', 'Position', [25 174 55 188]);
add_block('simulink/Sources/In1', [logging '/adc_values'], ...
    'Port', '4', 'Position', [25 235 55 249]);

add_block('simulink/Signal Routing/Bus Selector', [logging '/Measured Speed'], ...
    'OutputSignals', 'speed', 'Position', [105 82 110 116]);
add_block('simulink/Math Operations/Gain', [logging '/rad_s to rpm'], ...
    'Gain', '30/pi', 'Position', [140 84 195 114]);
add_block('simulink/Signal Attributes/Data Type Conversion', ...
    [logging '/Speed to single'], 'OutDataTypeStr', 'single', ...
    'Position', [210 84 245 114]);
add_block('simulink/Signal Routing/Mux', [logging '/Speed Pair'], ...
    'Inputs', '2', 'Position', [255 32 260 116]);

add_block('simulink/Sinks/Scope', [logging '/Speed'], ...
    'Position', [310 56 340 86]);
configureScope([logging '/Speed'], 'scope_speed');
add_block('simulink/Sinks/Scope', [logging '/Duty'], ...
    'Position', [310 166 340 196]);
configureScope([logging '/Duty'], 'scope_duty');
add_block('simulink/Sinks/Scope', [logging '/ADC'], ...
    'Position', [310 226 340 256]);
configureScope([logging '/ADC'], 'scope_adc_signals');

add_line(logging, 'speed_ref_rpm/1', 'Speed Pair/1');
add_line(logging, 'measurements/1', 'Measured Speed/1');
add_line(logging, 'Measured Speed/1', 'rad_s to rpm/1');
add_line(logging, 'rad_s to rpm/1', 'Speed to single/1');
add_line(logging, 'Speed to single/1', 'Speed Pair/2');
add_line(logging, 'Speed Pair/1', 'Speed/1');
add_line(logging, 'duty/1', 'Duty/1');
add_line(logging, 'adc_values/1', 'ADC/1');

% Branch the already-existing common signals; no telemetry leaves Processor.
safeLine(processor, 'setpoints/1', 'Logging/1');
safeLine(processor, 'measurements/1', 'Logging/2');
safeLine(processor, 'Controller Mode/1', 'Logging/3');
safeLine(processor, 'ADC_Interface/1', 'Logging/4');

Simulink.BlockDiagram.arrangeSystem(logging);
save_system(model, modelFile);
close_system(model, 0);
fprintf('Configured Processor-local common SIL/HIL logging in %s.\n', modelFile);

function configureScope(block, variable)
set_param(block, 'SaveToWorkspace', 'on', 'SaveName', variable, ...
    'DataFormat', 'Dataset', 'LimitDataPoints', 'off');
end

function safeDelete(block)
if getSimulinkBlockHandle(block) ~= -1
    delete_block(block);
end
end

function safeLine(parent, source, destination)
try
    add_line(parent, source, destination, 'autorouting', 'on');
catch ME
    if ~contains(ME.message, 'already') && ~contains(ME.message, 'connected')
        rethrow(ME);
    end
end
end
