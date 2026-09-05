%% test_mtpa_block_isolated.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

fprintf('Testing MTPA block math directly across speeds...\n');
N_test = [5000, 8000, 10000, 12000, 14000, 16000, 18000, 20000];
T_cmd = 20.0; % Nm

mdl = 'test_mtpa_direct';
if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
new_system(mdl);
add_block('mcbcontrolslib/MTPA Control Reference', [mdl, '/MTPA']);
set_param([mdl, '/MTPA'], ...
    'VariantSelect', 'Interior PMSM', ...
    'Units', 'SI Units', ...
    'Vdc_input_select', 'Specify via dialog', ...
    'V_dc', 'pmsm.V_rated', ...
    'polePairs', 'pmsm.P', ...
    'Rs', 'pmsm.Rs', ...
    'Ld', 'pmsm.Ld', ...
    'Lq', 'pmsm.Lq', ...
    'FluxPM', 'pmsm.fl', ...
    'ilimit', 'pmsm.I_rated', ...
    'N_base', 'pmsm.N_base');

add_block('simulink/Sources/Constant', [mdl, '/Tref'], 'Value', num2str(T_cmd));
add_block('simulink/Sources/Constant', [mdl, '/Spd_rads'], 'Value', '0');
add_block('simulink/Sinks/To Workspace', [mdl, '/id_out'], 'VariableName', 'id_sim', 'SaveFormat', 'Array');
add_block('simulink/Sinks/To Workspace', [mdl, '/iq_out'], 'VariableName', 'iq_sim', 'SaveFormat', 'Array');

add_line(mdl, 'Tref/1', 'MTPA/1');
add_line(mdl, 'Spd_rads/1', 'MTPA/2');
add_line(mdl, 'MTPA/1', 'id_out/1');
add_line(mdl, 'MTPA/2', 'iq_out/1');

fprintf('\n--- Testing with Speed in rad/s (mech) ---\n');
for N = N_test
    w_rads = N * pi/30;
    set_param([mdl, '/Spd_rads'], 'Value', num2str(w_rads));
    simOut = sim(mdl, 'StopTime', '0.001');
    id_val = simOut.id_sim(end);
    iq_val = simOut.iq_sim(end);
    fprintf('  N = %5d RPM (w = %7.1f rad/s) -> id = %6.2f A, iq = %6.2f A\n', N, w_rads, id_val, iq_val);
end

fprintf('\n--- Testing with Speed in RPM ---\n');
for N = N_test
    set_param([mdl, '/Spd_rads'], 'Value', num2str(N));
    simOut = sim(mdl, 'StopTime', '0.001');
    id_val = simOut.id_sim(end);
    iq_val = simOut.iq_sim(end);
    fprintf('  N = %5d (val = %5d) -> id = %6.2f A, iq = %6.2f A\n', N, N, id_val, iq_val);
end

close_system(mdl, 0);
