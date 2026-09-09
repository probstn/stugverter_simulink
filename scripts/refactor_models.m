%% refactor_models.m
% One-time/idempotent project migration to explicit SIL, HIL and HW models.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
modelsDir = fullfile(simulinkDir, 'models');
addpath(modelsDir);

plantModels = {'stugverter_sil', 'stugverter_hil'};
for k = 1:numel(plantModels)
    modelName = plantModels{k};
    load_system(fullfile(modelsDir, [modelName '.slx']));
    replacePlantPair(modelName);
    if strcmp(modelName, 'stugverter_hil')
        ensureDutyConversion(modelName);
    end
    set_param(modelName, 'EnablePacing', 'off');
    save_system(modelName);
    close_system(modelName, 0);
end

% SIL contains only the deployable algorithm path.  Keeping XCP blocks in an
% unselected Manual Switch branch still initializes the network interface.
modelName = 'stugverter_sil';
load_system(fullfile(modelsDir, [modelName '.slx']));
processor = [modelName '/Processor'];
removeBlocks(processor, {'HIL_Interface', 'HIL_Switch', ...
    'Scope_HW_Telemetry', 'Scope_SIL_vs_HIL'});
rebuildSilProcessor(processor);
set_param(modelName, 'EnablePacing', 'off');
save_system(modelName);
close_system(modelName, 0);

% Actual-hardware view is deliberately read-only: DAQ monitoring only, no
% simulated plant and no STIM block capable of overriding physical ADC data.
sourceModel = 'stugverter_hil';
load_system(fullfile(modelsDir, [sourceModel '.slx']));
modelName = 'stugverter_hw';
if bdIsLoaded(modelName), close_system(modelName, 0); end
new_system(modelName);
source = [sourceModel '/Processor/HIL_Interface/'];
add_block([source 'XCP UDP Configuration'], ...
    [modelName '/XCP UDP Configuration'], 'Position', [120 60 300 110]);
add_block([source 'XCP UDP Data Acquisition'], ...
    [modelName '/XCP UDP Data Acquisition'], 'Position', [120 170 300 360]);
add_block('simulink/Signal Routing/Mux', [modelName '/Telemetry'], ...
    'Inputs', '5', 'Position', [390 180 395 320]);
add_block('simulink/Sinks/Scope', [modelName '/Hardware Monitor'], ...
    'Position', [470 220 510 260]);
add_block('simulink/Sinks/To Workspace', [modelName '/Log Hardware Telemetry'], ...
    'VariableName', 'hardware_telemetry', 'SaveFormat', 'Structure With Time', ...
    'Position', [470 285 595 315]);
add_block('simulink/Sinks/Terminator', [modelName '/Timestamp'], ...
    'Position', [390 345 410 365]);
for p = 1:5
    add_line(modelName, sprintf('XCP UDP Data Acquisition/%d', p), ...
        sprintf('Telemetry/%d', p), 'autorouting', 'on');
end
add_line(modelName, 'Telemetry/1', 'Hardware Monitor/1', 'autorouting', 'on');
add_line(modelName, 'Telemetry/1', 'Log Hardware Telemetry/1', 'autorouting', 'on');
add_line(modelName, 'XCP UDP Data Acquisition/6', 'Timestamp/1', 'autorouting', 'on');
close_system(sourceModel, 0);
set_param([modelName '/XCP UDP Configuration'], 'SlaveName', 'TC387');
set_param(modelName, 'EnablePacing', 'off', 'StopTime', '10');
save_system(modelName, fullfile(modelsDir, [modelName '.slx']));
close_system(modelName, 0);

fprintf('[+] Model structure migrated; pacing is disabled on disk.\n');

function rebuildSilProcessor(processor)
converter = [processor '/Duty_to_double'];
if getSimulinkBlockHandle(converter) == -1
    add_block('simulink/Signal Attributes/Data Type Conversion', converter, ...
        'OutDataTypeStr', 'double', 'Position', [1100 570 1160 600]);
end
lines = find_system(processor, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'line');
for k = 1:numel(lines)
    try
        delete_line(lines(k));
    catch
        % A branch handle can become invalid when its parent line is removed.
    end
end
connections = {
    'setpoints/1', 'Model/1';
    'setpoints/1', 'Mux_Speed/1';
    'measurements/1', 'ADC_Interface/1';
    'measurements/1', 'Bus_Selector_Speed/1';
    'ADC_Interface/1', 'Model/2';
    'Model/1', 'SIL_PWM_Update_Delay/1';
    'SIL_PWM_Update_Delay/1', 'Duty_to_double/1';
    'Duty_to_double/1', 'duty/1';
    'Bus_Selector_Speed/1', 'Gain_rads2rpm/1';
    'Gain_rads2rpm/1', 'Mux_Speed/2';
    'Mux_Speed/1', 'Scope_Speed/1'};
for k = 1:size(connections, 1)
    add_line(processor, connections{k, 1}, connections{k, 2}, 'autorouting', 'on');
end
end

function ensureDutyConversion(modelName)
block = [modelName '/Duty to plant double'];
srcPorts = get_param([modelName '/Processor'], 'PortHandles');
dstPorts = get_param([modelName '/Plant'], 'PortHandles');
line = get_param(dstPorts.Inport(1), 'Line');
if line ~= -1, delete_line(line); end
if getSimulinkBlockHandle(block) == -1
    add_block('simulink/Signal Attributes/Data Type Conversion', block, ...
        'OutDataTypeStr', 'double', 'Position', [870 290 940 320]);
end
converterPorts = get_param(block, 'PortHandles');
if get_param(converterPorts.Inport(1), 'Line') == -1
    add_line(modelName, srcPorts.Outport(1), converterPorts.Inport(1), ...
        'autorouting', 'on');
end
add_line(modelName, converterPorts.Outport(1), dstPorts.Inport(1), ...
    'autorouting', 'on');
end

function replacePlantPair(modelName)
plantPath = [modelName '/Plant'];
processorPorts = get_param([modelName '/Processor'], 'PortHandles');
if getSimulinkBlockHandle(plantPath) == -1
    for name = {'Inverter', 'Motor'}
        path = [modelName '/' name{1}];
        if getSimulinkBlockHandle(path) ~= -1, delete_block(path); end
    end
    add_block('simulink/Ports & Subsystems/Model', plantPath, ...
        'ModelName', 'plant', 'Position', [960 269 1195 391]);
end
plantPorts = get_param(plantPath, 'PortHandles');
line = get_param(plantPorts.Inport(1), 'Line');
if line ~= -1, delete_line(line); end
line = get_param(processorPorts.Inport(2), 'Line');
if line ~= -1, delete_line(line); end
add_line(modelName, processorPorts.Outport(1), plantPorts.Inport(1), ...
    'autorouting', 'on');
add_line(modelName, plantPorts.Outport(1), processorPorts.Inport(2), ...
    'autorouting', 'on');
end

function removeBlocks(parent, names)
for n = 1:numel(names)
    block = [parent '/' names{n}];
    if getSimulinkBlockHandle(block) ~= -1
        delete_block(block);
    end
end
end
