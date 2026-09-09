%% build_demo_supervisor.m
% Add the first production-style supervisor/protection/arbitration slice to
% algorithm.slx without changing its external ports.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(simulinkDir, 'models'), fullfile(simulinkDir, 'scripts'));
run(fullfile(simulinkDir, 'scripts', 'init.m'));
model = 'algorithm';
load_system(fullfile(simulinkDir, 'models', [model '.slx']));
ensureResolverOffset(model);

% Remove a prior generated supervisor area so this script is repeatable.
for name = {'Demo Supervisor', 'Mode Request', 'Enable Request', 'Fault Reset', ...
        'Protection Signals', 'ADC Protection Signals', 'Protection Monitor', ...
        'Demo Output Arbitration', 'Torque Mode', 'Torque Reference', ...
        'Torque Select', 'Calibration Modulation', 'Open Loop Modulation', ...
        'Open Loop Frequency'}
    path = [model '/' name{1}];
    if getSimulinkBlockHandle(path) ~= -1, delete_block(path); end
end
cleanDanglingLines(model);

add_block('simulink/Sources/Constant', [model '/Mode Request'], ...
    'Value', 'control_mode_request', 'OutDataTypeStr', 'uint8', ...
    'Position', [35 650 120 680]);
add_block('simulink/Sources/Constant', [model '/Enable Request'], ...
    'Value', 'control_enable_request', 'OutDataTypeStr', 'boolean', ...
    'Position', [35 695 120 725]);
add_block('simulink/Sources/Constant', [model '/Fault Reset'], ...
    'Value', 'control_fault_reset', 'OutDataTypeStr', 'boolean', ...
    'Position', [35 740 120 770]);

add_block('simulink/Signal Routing/Bus Selector', [model '/Protection Signals'], ...
    'OutputSignals', 'currents,speed', 'Position', [285 535 290 590]);
add_block('simulink/Signal Routing/Bus Selector', [model '/ADC Protection Signals'], ...
    'OutputSignals', 'ia,ib,ic,resolver_sin,resolver_cos', ...
    'Position', [40 565 45 635]);
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model '/Protection Monitor'], 'Position', [350 540 510 625]);
protectionChart = find(sfroot, '-isa', 'Stateflow.EMChart', ...
    'Path', [model '/Protection Monitor']);
protectionChart.Script = sprintf([ ...
    'function fault = protection_monitor(currents, speed, ia, ib, ic, rsin, rcos)\n', ...
    '%%#codegen\n', ...
    'overcurrent = any(abs(currents) > single(105));\n', ...
    'overspeed = abs(speed) > single(2094.3951);\n', ...
    'adcRail = ia <= uint16(8) || ia >= uint16(4087) || ...\n', ...
    '          ib <= uint16(8) || ib >= uint16(4087) || ...\n', ...
    '          ic <= uint16(8) || ic >= uint16(4087);\n', ...
    's = (single(rsin)-2048.0)/2047.0; c = (single(rcos)-2048.0)/2047.0;\n', ...
    'resolverAmplitude = sqrt(s*s+c*c);\n', ...
    'resolverBad = resolverAmplitude < single(0.35) || ...\n', ...
    '              resolverAmplitude > single(1.30);\n', ...
    'fault = overcurrent || overspeed || adcRail || resolverBad;\n', ...
    'end\n']);
setEmData(protectionChart, 'currents', 'single', '[3]');
setEmData(protectionChart, 'speed', 'single', '1');
for name = {'ia','ib','ic','rsin','rcos'}
    setEmData(protectionChart, name{1}, 'uint16', '1');
end
setEmData(protectionChart, 'fault', 'boolean', '1');

add_block('sflib/Chart', [model '/Demo Supervisor'], ...
    'Position', [560 555 735 700]);
chart = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', [model '/Demo Supervisor']);
chart.ActionLanguage = 'C';
addSfData(chart, 'mode_request', 'Input', 'uint8');
addSfData(chart, 'enable_request', 'Input', 'boolean');
addSfData(chart, 'fault_active', 'Input', 'boolean');
addSfData(chart, 'reset_fault', 'Input', 'boolean');
addSfData(chart, 'active_mode', 'Output', 'uint8');
addSfData(chart, 'pwm_enable', 'Output', 'boolean');
addSfData(chart, 'fault_latched', 'Output', 'boolean');

states = struct;
states.OFF = makeState(chart, 'OFF', [40 40 110 55], ...
    'entry: active_mode=0; pwm_enable=false; fault_latched=false;');
states.CALIBRATION = makeState(chart, 'CALIBRATION', [220 15 145 55], ...
    'entry: active_mode=1; pwm_enable=true;');
states.OPEN_LOOP = makeState(chart, 'OPEN_LOOP', [220 90 145 55], ...
    'entry: active_mode=2; pwm_enable=true;');
states.SPEED_FOC = makeState(chart, 'SPEED_FOC', [220 165 145 55], ...
    'entry: active_mode=3; pwm_enable=true;');
states.TORQUE_FOC = makeState(chart, 'TORQUE_FOC', [220 240 145 55], ...
    'entry: active_mode=4; pwm_enable=true;');
states.FAULT = makeState(chart, 'FAULT', [430 115 120 65], ...
    'entry: active_mode=0; pwm_enable=false; fault_latched=true;');
defaultTransition = Stateflow.Transition(chart);
defaultTransition.Destination = states.OFF;
defaultTransition.DestinationOClock = 0;
defaultTransition.SourceEndPoint = [20 67];
defaultTransition.MidPoint = [30 67];
for mode = 1:4
    names = {'CALIBRATION','OPEN_LOOP','SPEED_FOC','TORQUE_FOC'};
    addTransition(chart, states.OFF, states.(names{mode}), ...
        sprintf('[enable_request && mode_request==%d]', mode));
end
activeNames = {'CALIBRATION','OPEN_LOOP','SPEED_FOC','TORQUE_FOC'};
for k = 1:numel(activeNames)
    state = states.(activeNames{k});
    addTransition(chart, state, states.FAULT, '[fault_active]');
    addTransition(chart, state, states.OFF, '[!enable_request]');
end
addTransition(chart, states.FAULT, states.OFF, '[reset_fault && !fault_active]');

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model '/Demo Output Arbitration'], 'Position', [850 520 1040 620]);
arbiter = find(sfroot, '-isa', 'Stateflow.EMChart', ...
    'Path', [model '/Demo Output Arbitration']);
arbiter.Script = sprintf([ ...
    'function duty = arbitrate(active_mode,pwm_enable,foc_duty,cal_mod,ol_mod,ol_hz)\n', ...
    '%%#codegen\n', ...
    'persistent theta\n', ...
    'if isempty(theta)\n', ...
    ' theta=single(0);\n', ...
    'end\n', ...
    'duty=single([0.5;0.5;0.5]);\n', ...
    'if ~pwm_enable\n', ...
    ' theta=single(0);\n', ...
    ' return\n', ...
    'end\n', ...
    'if active_mode==1\n', ...
    ' m=single(cal_mod); duty(1)=single(0.5)+m; duty(2)=single(0.5)-single(0.5)*m; duty(3)=duty(2);\n', ...
    'elseif active_mode==2\n', ...
    ' twoPi=single(6.283185307179586); theta=theta+twoPi*single(ol_hz)*single(0.00005);\n', ...
    ' if theta>twoPi, theta=theta-twoPi; end\n', ...
    ' m=single(ol_mod); duty(1)=single(0.5)+m*cos(theta); duty(2)=single(0.5)+m*cos(theta-single(2.094395102393195)); duty(3)=single(0.5)+m*cos(theta+single(2.094395102393195));\n', ...
    'elseif active_mode==3 || active_mode==4\n', ...
    ' duty=min(max(single(foc_duty),single(0.02)),single(0.98));\n', ...
    'end\n', ...
    'end\n']);
setEmData(arbiter, 'active_mode', 'uint8', '1');
setEmData(arbiter, 'pwm_enable', 'boolean', '1');
setEmData(arbiter, 'foc_duty', 'single', '[3]');
setEmData(arbiter, 'cal_mod', 'single', '1');
setEmData(arbiter, 'ol_mod', 'single', '1');
setEmData(arbiter, 'ol_hz', 'single', '1');
setEmData(arbiter, 'duty', 'single', '[3]');

add_block('simulink/Sources/Constant', [model '/Calibration Modulation'], ...
    'Value', 'calibration_modulation', 'OutDataTypeStr', 'single', ...
    'Position', [680 735 805 765]);
add_block('simulink/Sources/Constant', [model '/Open Loop Modulation'], ...
    'Value', 'open_loop_modulation', 'OutDataTypeStr', 'single', ...
    'Position', [680 775 805 805]);
add_block('simulink/Sources/Constant', [model '/Open Loop Frequency'], ...
    'Value', 'open_loop_electrical_hz', 'OutDataTypeStr', 'single', ...
    'Position', [680 815 805 845]);

% Torque mode bypasses only the speed PI; MTPA/FW and current control stay shared.
add_block('simulink/Logic and Bit Operations/Compare To Constant', ...
    [model '/Torque Mode'], 'const', '4', 'relop', '==', ...
    'Position', [430 410 500 440]);
add_block('simulink/Sources/Constant', [model '/Torque Reference'], ...
    'Value', 'torque_ref_nm', 'OutDataTypeStr', 'single', ...
    'Position', [430 385 510 405]);
add_block('simulink/Signal Routing/Switch', [model '/Torque Select'], ...
    'Threshold', '0.5', 'Criteria', 'u2 >= Threshold', ...
    'Position', [535 390 575 445]);

% Replace only the two existing lines whose ownership changes.
deleteDestinationLine([model '/duty_cycles'], 1);
deleteDestinationLine([model '/MTPA Control Reference'], 1);

add_line(model, 'adc_to_sensor/1', 'Protection Signals/1', 'autorouting', 'on');
add_line(model, 'adc_values/1', 'ADC Protection Signals/1', 'autorouting', 'on');
add_line(model, 'Protection Signals/1', 'Protection Monitor/1', 'autorouting', 'on');
add_line(model, 'Protection Signals/2', 'Protection Monitor/2', 'autorouting', 'on');
for p = 1:5
    add_line(model, sprintf('ADC Protection Signals/%d',p), ...
        sprintf('Protection Monitor/%d',p+2), 'autorouting', 'on');
end
add_line(model, 'Mode Request/1', 'Demo Supervisor/1', 'autorouting', 'on');
add_line(model, 'Enable Request/1', 'Demo Supervisor/2', 'autorouting', 'on');
add_line(model, 'Protection Monitor/1', 'Demo Supervisor/3', 'autorouting', 'on');
add_line(model, 'Fault Reset/1', 'Demo Supervisor/4', 'autorouting', 'on');
add_line(model, 'Demo Supervisor/1', 'Demo Output Arbitration/1', 'autorouting', 'on');
add_line(model, 'Demo Supervisor/2', 'Demo Output Arbitration/2', 'autorouting', 'on');
add_line(model, 'current_control/1', 'Demo Output Arbitration/3', 'autorouting', 'on');
add_line(model, 'Calibration Modulation/1', 'Demo Output Arbitration/4', 'autorouting', 'on');
add_line(model, 'Open Loop Modulation/1', 'Demo Output Arbitration/5', 'autorouting', 'on');
add_line(model, 'Open Loop Frequency/1', 'Demo Output Arbitration/6', 'autorouting', 'on');
add_line(model, 'Demo Output Arbitration/1', 'duty_cycles/1', 'autorouting', 'on');
add_line(model, 'Demo Supervisor/1', 'Torque Mode/1', 'autorouting', 'on');
add_line(model, 'Torque Reference/1', 'Torque Select/1', 'autorouting', 'on');
add_line(model, 'Torque Mode/1', 'Torque Select/2', 'autorouting', 'on');
add_line(model, 'speed_control/1', 'Torque Select/3', 'autorouting', 'on');
add_line(model, 'Torque Select/1', 'MTPA Control Reference/1', 'autorouting', 'on');

set_param(model, 'EnablePacing', 'off');
save_system(model);
close_system(model, 0);
fprintf('[+] Demo supervisor, protection monitor and mode arbitration added.\n');

function data = addSfData(chart, name, scope, type)
data = Stateflow.Data(chart);
data.Name = name;
data.Scope = scope;
data.Props.Type.Method = 'Built-in';
data.DataType = type;
end

function setEmData(chart, name, type, sizeValue)
data = chart.find('-isa', 'Stateflow.Data', 'Name', name);
data.DataType = type;
data.Props.Array.Size = sizeValue;
end

function state = makeState(chart, name, position, action)
state = Stateflow.State(chart);
state.Name = name;
state.Position = position;
state.LabelString = sprintf('%s\n%s', name, action);
end

function transition = addTransition(chart, source, destination, condition)
transition = Stateflow.Transition(chart);
transition.Source = source;
transition.Destination = destination;
transition.LabelString = condition;
end

function deleteDestinationLine(block, port)
ports = get_param(block, 'PortHandles');
line = get_param(ports.Inport(port), 'Line');
if line ~= -1, delete_line(line); end
end

function cleanDanglingLines(model)
lines = find_system(model, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'line');
for k = 1:numel(lines)
    try
        if get_param(lines(k), 'SrcBlockHandle') == -1 || ...
                any(get_param(lines(k), 'DstBlockHandle') == -1)
            delete_line(lines(k));
        end
    catch
    end
end
end

function ensureResolverOffset(model)
parent = [model '/adc_to_sensor/Position measurement'];
sumBlock = [parent '/Apply resolver zero offset'];
if getSimulinkBlockHandle(sumBlock) ~= -1, return; end
wrap = [parent '/Wrap to one turn'];
wrapPorts = get_param(wrap, 'PortHandles');
angleLine = get_param(wrapPorts.Inport(1), 'Line');
if angleLine ~= -1, delete_line(angleLine); end
add_block('simulink/Sources/Constant', [parent '/Resolver zero offset'], ...
    'Value', 'resolver_angle_offset', 'OutDataTypeStr', 'single', ...
    'Position', [625 45 715 75]);
add_block('simulink/Math Operations/Sum', sumBlock, 'Inputs', '+-', ...
    'Position', [640 95 670 135]);
add_line(parent, 'atan2 sin cos/1', 'Apply resolver zero offset/1');
add_line(parent, 'Resolver zero offset/1', 'Apply resolver zero offset/2');
add_line(parent, 'Apply resolver zero offset/1', 'Wrap to one turn/1');
end
