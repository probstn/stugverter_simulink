%% configure_hil_mode_stim.m
% Include supervisor mode/enable in the same atomic STIM packet as HIL ADC data.
simulinkDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(simulinkDir, 'models'), fullfile(simulinkDir, 'scripts'));
run(fullfile(simulinkDir, 'scripts', 'init.m'));
simulation_mode.Value = uint8(1);
assignin('base', 'simulation_mode', simulation_mode);
model = 'stugverter_sim';
load_system(fullfile(simulinkDir, 'models', [model '.slx']));
parent = [model '/Processor/Controller Mode/HIL/XCP HIL'];
stim = [parent '/XCP UDP Data Stimulation'];
set_param(stim, 'SelectedMeasurements', [ ...
    'g_hil_mode_enable;g_spd_ref_rpm;g_hil_adc_curr_u;g_hil_adc_curr_v;', ...
    'g_hil_adc_curr_w;g_hil_adc_res_sin;g_hil_adc_res_cos;', ...
    'control_mode_request;control_enable_request;resolver_angle_offset']);
if getSimulinkBlockHandle([parent '/HIL Control Mode']) == -1
    add_block('simulink/Sources/Constant', [parent '/HIL Control Mode'], ...
        'Value', 'hil_control_mode_request', 'OutDataTypeStr', 'double', ...
        'Position', [360 550 470 580]);
    add_block('simulink/Sources/Constant', [parent '/HIL Control Enable'], ...
        'Value', '1', 'OutDataTypeStr', 'double', ...
        'Position', [360 595 470 625]);
    add_block('simulink/Sources/Constant', [parent '/HIL Resolver Offset'], ...
        'Value', '0', 'OutDataTypeStr', 'double', ...
        'Position', [360 640 470 670]);
    add_line(parent, 'HIL Control Mode/1', 'XCP UDP Data Stimulation/8', 'autorouting', 'on');
    add_line(parent, 'HIL Control Enable/1', 'XCP UDP Data Stimulation/9', 'autorouting', 'on');
    add_line(parent, 'HIL Resolver Offset/1', 'XCP UDP Data Stimulation/10', 'autorouting', 'on');
end
save_system(model);
close_system(model, 0);
fprintf('[+] HIL supervisor request is transported atomically in every STIM packet.\n');
