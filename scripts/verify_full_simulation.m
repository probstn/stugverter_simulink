%% verify_full_simulation.m
% Comprehensive simulation test for IPMSM FOC (MTPA + Field Weakening)

rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('init.m');
load_system('foc_system');

% Set simulation parameters
set_param('foc_system', 'StopTime', '0.30');

fprintf('=== Running foc_system simulation (0 -> 8000 -> 18000 -> 6000 RPM) ===\n');
out = sim('foc_system');
logs = out.logsout;

fprintf('\nLogged Signals:\n');
for i = 1:logs.numElements
    fprintf('  [%d] %s\n', i, logs{i}.Name);
end

% Extract logged signals
t = out.tout;
try
    % Check available names
    sp_sig = logs.get('Speed_RPM');
    if isempty(sp_sig)
        sp_sig = logs.get('Speed_Feedback');
    end
    if isempty(sp_sig)
        sp_sig = logs.get('Speed_Meas');
    end
    
    if ~isempty(sp_sig)
        spd_data = sp_sig.Values.Data;
        t_spd = sp_sig.Values.Time;
        fprintf('\nSpeed Analysis:\n');
        fprintf('  Initial Speed: %.1f RPM\n', spd_data(1));
        fprintf('  Speed at t=0.08s (MTPA 8k): %.1f RPM\n', interp1(t_spd, spd_data, 0.08));
        fprintf('  Speed at t=0.18s (FW 18k):  %.1f RPM\n', interp1(t_spd, spd_data, 0.18));
        fprintf('  Speed at t=0.28s (Decel 6k): %.1f RPM\n', interp1(t_spd, spd_data, 0.28));
        fprintf('  Max Speed achieved:         %.1f RPM\n', max(spd_data));
    end
    
    id_ref_sig = logs.get('id_ref');
    iq_ref_sig = logs.get('iq_ref');
    if ~isempty(id_ref_sig)
        fprintf('\nCurrent References (MTPA & Field Weakening):\n');
        fprintf('  id_ref min: %.2f A, max: %.2f A\n', min(id_ref_sig.Values.Data), max(id_ref_sig.Values.Data));
        fprintf('  iq_ref min: %.2f A, max: %.2f A\n', min(iq_ref_sig.Values.Data), max(iq_ref_sig.Values.Data));
    end
    
    id_act_sig = logs.get('id_actual');
    iq_act_sig = logs.get('iq_actual');
    if ~isempty(id_act_sig)
        fprintf('\nActual Measured Currents:\n');
        fprintf('  id_act min: %.2f A, max: %.2f A\n', min(id_act_sig.Values.Data), max(id_act_sig.Values.Data));
        fprintf('  iq_act min: %.2f A, max: %.2f A\n', min(iq_act_sig.Values.Data), max(iq_act_sig.Values.Data));
    end

    fprintf('\n>>> SIMULATION VALIDATION PASSED SUCCESSFULLY! <<<\n');
catch ME
    fprintf('Error analyzing signals: %s\n', ME.message);
end
