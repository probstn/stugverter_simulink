%% cleanup_algorithm_top_level.m
% Deterministically rebuilds the algorithm.slx top-level presentation.
% Control internals are preserved; long cross-sheet signals use named tags.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(simulinkDir, 'scripts', 'refactor_algorithm_supervisor.m'));
modelPath = fullfile(simulinkDir, 'models', 'algorithm.slx');
load_system(modelPath);
model = 'algorithm';

% Remove prior generated routing blocks and rebuild every top-level net.
generated = find_system(model, 'SearchDepth', 1, 'Type', 'Block', ...
    'Tag', 'algorithm_clean_routing');
for k = 1:numel(generated)
    delete_block(generated{k});
end
lines = find_system(model, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'Line');
for k = reshape(lines, 1, [])
    try, delete_line(k); catch, end
end
% The old canvas used free-floating section captions; replace all top-level
% annotations so stale mode numbering cannot survive the deterministic layout.
annotations = find_system(model, 'FindAll', 'on', 'SearchDepth', 1, ...
    'Type', 'Annotation');
for k = reshape(annotations, 1, [])
    delete(k);
end

% White canvas and a left-to-right signal-flow layout.
set_param(model, 'ScreenColor', 'white');
place('Speed Reference (rpm)',       [30 100 160 130],  '#FFFFFF');
place('RPM to rad-s',                [200 95 285 135],  '#FFFFFF');
place('Speed PI',                    [390 75 545 145],  '#DCEBFA');
place('Torque Reference',            [385 25 545 50],   '#FFFFFF');
place('Torque Mode Active',          [390 175 535 210], '#FFF2CC');
if getSimulinkBlockHandle([model '/Torque Command Select']) > 0
    place('Torque Command Select',   [590 45 630 165],  '#DCEBFA');
else
    place('Speed or Torque Select',  [590 45 630 165],  '#DCEBFA');
    set_param([model '/Speed or Torque Select'], 'Name', 'Torque Command Select');
end
place('MTPA + Field Weakening',      [700 75 895 155],  '#DCEBFA');
place('FOC Current Control',         [1000 65 1190 165], '#DCEBFA');
place('FOC Duty Vector',             [1235 100 1280 135], '#FFFFFF');
place('Duty Command Arbitration',    [1450 70 1665 220], '#EADCF8');
place('PWM Duty Cycles',             [1760 125 1885 155], '#FFFFFF');
arbTerm = [model '/Arbitration Debug Terminator'];
if getSimulinkBlockHandle(arbTerm) <= 0
    add_block('simulink/Sinks/Terminator', arbTerm, ...
        'Tag', 'algorithm_clean_routing');
end
place('Arbitration Debug Terminator', [1705 190 1725 210], '#FFFFFF');
place('Calibration Voltage',         [1425 250 1570 280], '#FFFFFF');
place('Open-loop Voltage',           [1425 300 1570 330], '#FFFFFF');
place('Open-loop Frequency',         [1425 350 1570 380], '#FFFFFF');

place('Raw ADC Measurements',        [30 430 160 460], '#FFFFFF');
place('Sensor Decoding',             [300 390 500 500], '#E2F0D9');
place('Feedback Signals',            [580 405 590 455], '#FFFFFF');
place('Physical Feedback',           [650 390 660 465], '#FFFFFF');
place('Raw ADC Checks',              [650 485 660 635], '#FFFFFF');
place('Protection Monitor',          [770 430 970 535], '#FCE4D6');
place('Sensor Offset Calibration',   [300 590 520 745], '#FFF2CC');
place('Initial Current Offsets',      [30 650 190 680], '#FFFFFF');
place('Initial Resolver Offset',     [30 705 190 735], '#FFFFFF');

place('Requested Mode',              [1040 610 1190 640], '#FFFFFF');
place('Enable Command',              [1040 655 1190 685], '#FFFFFF');
place('Calibration Request',         [1040 700 1190 730], '#FFFFFF');
place('Fault Reset Command',         [1040 745 1190 775], '#FFFFFF');
place('Has Stored Resolver Offset',  [1040 790 1190 820], '#FFFFFF');
place('Operating Mode Supervisor',   [1320 610 1580 825], '#F8CBAD');
place('Supervisor State Terminator', [1740 775 1760 795], '#FFFFFF');
place('Fault Latched Status',        [1740 735 1760 755], '#FFFFFF');

% Named signals. Global visibility keeps generated-code semantics simple and
% makes every long dependency explicit on the diagram.
addGoto('RAW_ADC',              [190 425 285 455]);
addFrom('RAW_ADC',              [195 410 270 440], 'Raw ADC to Decoder');
addFrom('RAW_ADC',              [195 545 270 575], 'Raw ADC to Calibration');
addFrom('RAW_ADC',              [545 530 620 560], 'Raw ADC to Checks');

addGoto('MEASUREMENTS',         [520 405 625 435]);
addFrom('MEASUREMENTS',         [500 175 605 205], 'Measurements to FOC');
addFrom('MEASUREMENTS',         [500 400 605 430], 'Measurements to Feedback');
addFrom('MEASUREMENTS',         [545 455 650 485], 'Measurements to Safety');
addGoto('MEASURED_SPEED',       [610 405 715 435]);
addFrom('MEASURED_SPEED',       [300 145 385 175], 'Measured Speed');

addGoto('CURRENT_OFFSETS',      [545 610 650 640]);
addFrom('CURRENT_OFFSETS',      [180 465 285 495], 'Current Offsets');
addGoto('RESOLVER_OFFSET',      [545 660 650 690]);
addFrom('RESOLVER_OFFSET',      [180 420 285 450], 'Resolver Offset');
addGoto('CURRENT_CAL_DONE',     [545 705 665 735]);
addFrom('CURRENT_CAL_DONE',     [1195 735 1310 765], 'Current Cal Done');
addGoto('ANGLE_CAL_DONE',       [545 755 665 785]);
addFrom('ANGLE_CAL_DONE',       [1195 780 1310 810], 'Angle Cal Done');
addGoto('FAULT_ACTIVE',         [985 465 1080 495]);
addFrom('FAULT_ACTIVE',         [1195 690 1310 720], 'Fault Active');

addGoto('ACTIVE_MODE',          [1605 620 1700 650]);
addFrom('ACTIVE_MODE',          [285 180 380 210], 'Mode to Torque Select');
addFrom('ACTIVE_MODE',          [1325 75 1420 105], 'Mode to PWM Manager');
addGoto('PWM_ENABLE',           [1605 655 1700 685]);
addFrom('PWM_ENABLE',           [1325 110 1420 140], 'PWM Enable');
addGoto('CURRENT_CAL_ENABLE',   [1605 690 1730 720]);
addFrom('CURRENT_CAL_ENABLE',   [165 570 290 600], 'Current Cal Enable');
addGoto('ANGLE_ALIGN_ENABLE',   [1605 725 1730 755]);
addFrom('ANGLE_ALIGN_ENABLE',   [1320 145 1445 175], 'Angle Align Enable');
addGoto('ANGLE_SAMPLE_ENABLE',  [1605 760 1740 790]);
addFrom('ANGLE_SAMPLE_ENABLE',  [155 615 290 645], 'Angle Sample Enable');

% Main data path.
wire('Speed Reference (rpm)/1', 'RPM to rad-s/1');
wire('RPM to rad-s/1', 'Speed PI/1');
wire('Measured Speed/1', 'Speed PI/2');
wire('Measured Speed/1', 'MTPA + Field Weakening/2');
wire('Torque Reference/1', 'Torque Command Select/1');
wire('Mode to Torque Select/1', 'Torque Mode Active/1');
wire('Torque Mode Active/1', 'Torque Command Select/2');
wire('Speed PI/1', 'Torque Command Select/3');
wire('Torque Command Select/1', 'MTPA + Field Weakening/1');
wire('MTPA + Field Weakening/1', 'FOC Current Control/1');
wire('MTPA + Field Weakening/2', 'FOC Current Control/2');
wire('Measurements to FOC/1', 'FOC Current Control/3');
wire('FOC Current Control/1', 'FOC Duty Vector/1');
wire('FOC Duty Vector/1', 'Duty Command Arbitration/3');
wire('Mode to PWM Manager/1', 'Duty Command Arbitration/1');
wire('PWM Enable/1', 'Duty Command Arbitration/2');
wire('Angle Align Enable/1', 'Duty Command Arbitration/4');
wire('Calibration Voltage/1', 'Duty Command Arbitration/5');
wire('Open-loop Voltage/1', 'Duty Command Arbitration/6');
wire('Open-loop Frequency/1', 'Duty Command Arbitration/7');
wire('Duty Command Arbitration/1', 'PWM Duty Cycles/1');
wire('Duty Command Arbitration/2', 'Arbitration Debug Terminator/1');

% Sensor processing, protection, and calibration.
wire('Raw ADC Measurements/1', 'Goto RAW_ADC/1');
wire('Raw ADC to Decoder/1', 'Sensor Decoding/1');
wire('Sensor Decoding/1', 'Goto MEASUREMENTS/1');
wire('Resolver Offset/1', 'Sensor Decoding/2');
wire('Current Offsets/1', 'Sensor Decoding/3');
wire('Measurements to Feedback/1', 'Feedback Signals/1');
wire('Feedback Signals/1', 'Goto MEASURED_SPEED/1');
wire('Measurements to Safety/1', 'Physical Feedback/1');
wire('Physical Feedback/1', 'Protection Monitor/1');
wire('Physical Feedback/2', 'Protection Monitor/2');
wire('Raw ADC to Checks/1', 'Raw ADC Checks/1');
for port = 1:5
    wire(sprintf('Raw ADC Checks/%d', port), sprintf('Protection Monitor/%d', port + 2));
end
wire('Protection Monitor/1', 'Goto FAULT_ACTIVE/1');
wire('Raw ADC to Calibration/1', 'Sensor Offset Calibration/1');
wire('Current Cal Enable/1', 'Sensor Offset Calibration/2');
wire('Angle Sample Enable/1', 'Sensor Offset Calibration/3');
wire('Initial Current Offsets/1', 'Sensor Offset Calibration/4');
wire('Initial Resolver Offset/1', 'Sensor Offset Calibration/5');
wire('Sensor Offset Calibration/1', 'Goto CURRENT_OFFSETS/1');
wire('Sensor Offset Calibration/2', 'Goto RESOLVER_OFFSET/1');
wire('Sensor Offset Calibration/3', 'Goto CURRENT_CAL_DONE/1');
wire('Sensor Offset Calibration/4', 'Goto ANGLE_CAL_DONE/1');

% Central supervisor: local commands in, named decisions out.
wire('Requested Mode/1', 'Operating Mode Supervisor/1');
wire('Enable Command/1', 'Operating Mode Supervisor/2');
wire('Calibration Request/1', 'Operating Mode Supervisor/3');
wire('Fault Active/1', 'Operating Mode Supervisor/4');
wire('Fault Reset Command/1', 'Operating Mode Supervisor/5');
wire('Current Cal Done/1', 'Operating Mode Supervisor/6');
wire('Angle Cal Done/1', 'Operating Mode Supervisor/7');
wire('Has Stored Resolver Offset/1', 'Operating Mode Supervisor/8');
wire('Operating Mode Supervisor/1', 'Goto ACTIVE_MODE/1');
wire('Operating Mode Supervisor/2', 'Goto PWM_ENABLE/1');
wire('Operating Mode Supervisor/3', 'Goto CURRENT_CAL_ENABLE/1');
wire('Operating Mode Supervisor/4', 'Goto ANGLE_ALIGN_ENABLE/1');
wire('Operating Mode Supervisor/5', 'Goto ANGLE_SAMPLE_ENABLE/1');
wire('Operating Mode Supervisor/6', 'Fault Latched Status/1');
wire('Operating Mode Supervisor/7', 'Supervisor State Terminator/1');

% Lightweight visual hierarchy and an embedded legend.
note('CLOSED-LOOP CONTROL  |  TORQUE (1)  •  SPEED (2)', [30 5 900 25], [0.12 0.35 0.70]);
note('PWM OUTPUT  |  OPEN LOOP (3) AND CALIBRATION OVERRIDES', [1230 5 1880 25], [0.45 0.20 0.65]);
note('MEASUREMENT CONDITIONING, CALIBRATION AND PROTECTION', [30 350 970 375], [0.20 0.55 0.20]);
note('CENTRAL SUPERVISOR  |  IDLE → CALIBRATION → READY → RUN   (+ latched FAULT)', [1030 555 1880 580], [0.75 0.25 0.10]);
note(['Boot: current-zero always. Angle-zero only when requested or no stored offset.  ' ...
      'Mode changes while RUN force PWM off until enable is released and asserted again.'], ...
     [1030 850 1880 885], [0.25 0.25 0.25]);

set_param(model, 'ZoomFactor', 'FitSystem');
save_system(model, modelPath);
close_system(model, 0);
fprintf('[+] Clean algorithm top level rebuilt and saved.\n');

function place(name, position, background)
path = ['algorithm/' name];
switch background
    case '#DCEBFA', background = 'lightBlue';
    case '#FFF2CC', background = 'yellow';
    case '#E2F0D9', background = 'green';
    case '#FCE4D6', background = 'orange';
    case '#EADCF8', background = 'magenta';
    case '#F8CBAD', background = 'orange';
    otherwise, background = 'white';
end
set_param(path, 'Position', position, 'BackgroundColor', background, ...
    'ForegroundColor', 'black', 'FontName', 'Arial', 'FontSize', '10');
try, set_param(path, 'ShowPortLabels', 'FromPortIcon'); catch, end
end

function addGoto(tag, position)
name = ['Goto ' tag];
path = ['algorithm/' name];
add_block('simulink/Signal Routing/Goto', path, 'GotoTag', tag, ...
    'TagVisibility', 'global', 'Position', position, 'ShowName', 'off', ...
    'Tag', 'algorithm_clean_routing', 'BackgroundColor', 'yellow');
end

function addFrom(tag, position, name)
path = ['algorithm/' name];
add_block('simulink/Signal Routing/From', path, 'GotoTag', tag, ...
    'Position', position, 'ShowName', 'off', ...
    'Tag', 'algorithm_clean_routing', 'BackgroundColor', 'yellow');
end

function wire(source, destination)
add_line('algorithm', source, destination, 'autorouting', 'smart');
end

function note(text, position, color)
a = Simulink.Annotation('algorithm', text);
a.Position = position;
[~, colorIndex] = max(color);
palette = {'red', 'green', 'blue'};
a.ForegroundColor = palette{colorIndex};
a.FontName = 'Arial';
a.FontSize = 12;
a.FontWeight = 'bold';
a.Tag = 'algorithm_clean_routing';
end
