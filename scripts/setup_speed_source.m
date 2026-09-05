%% setup_speed_source.m
% Connects Speed_Profile (RPM) -> rpm2rads (rad/s) -> speed_control/1

rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('foc_system');

% Delete any existing line connected to speed_control/1
lh_sc = get_param('foc_system/speed_control', 'LineHandles');
if lh_sc.Inport(1) ~= -1
    delete_line(lh_sc.Inport(1));
end

% Delete existing line from Speed_Profile
if ~isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'Speed_Profile'))
    lh_sp = get_param('foc_system/Speed_Profile', 'LineHandles');
    if lh_sp.Outport(1) ~= -1
        delete_line(lh_sp.Outport(1));
    end
else
    add_block('simulink/Sources/From Workspace', 'foc_system/Speed_Profile', ...
        'Position', [60, 195, 140, 225], ...
        'VariableName', 'sp_ts', ...
        'SampleTime', '0');
end

% Ensure rpm2rads block exists and is properly positioned
if isempty(find_system('foc_system', 'SearchDepth', 1, 'Name', 'rpm2rads'))
    add_block('simulink/Math Operations/Gain', 'foc_system/rpm2rads', ...
        'Position', [180, 195, 230, 225], ...
        'Gain', 'pi/30');
else
    set_param('foc_system/rpm2rads', 'Gain', 'pi/30', 'Position', [180, 195, 230, 225]);
    lh_rpm = get_param('foc_system/rpm2rads', 'LineHandles');
    if lh_rpm.Inport(1) ~= -1
        delete_line(lh_rpm.Inport(1));
    end
    if lh_rpm.Outport(1) ~= -1
        delete_line(lh_rpm.Outport(1));
    end
end

% Wire: Speed_Profile -> rpm2rads -> speed_control/1
hLine1 = add_line('foc_system', 'Speed_Profile/1', 'rpm2rads/1', 'autorouting', 'on');
p1 = get_param(hLine1, 'SrcPortHandle');
set_param(p1, 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'spd_ref_rpm');

hLine2 = add_line('foc_system', 'rpm2rads/1', 'speed_control/1', 'autorouting', 'on');
p2 = get_param(hLine2, 'SrcPortHandle');
set_param(p2, 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', 'DataLoggingName', 'spd_ref_rads');

save_system('foc_system');
fprintf('foc_system speed references wired cleanly (RPM -> rad/s -> Controller)!\n');
