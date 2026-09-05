% plot_simulation_results.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');

% Test with Step to 18000 RPM (Field weakening region: base speed is 13650 RPM)
set_param('foc_system/Step1', 'Time', '0.05', 'Before', '0', 'After', '18000');
set_param('foc_system', 'StopTime', '0.2');

fprintf('Running simulation to 18000 RPM...\n');
try
    out = sim('foc_system');
    logs = out.logsout;
    t = logs.get('Speed_Meas').Values.Time;
    spd = logs.get('Speed_Meas').Values.Data * (30/pi); % Convert rad/s to RPM
    id_ref = logs.get('id_ref').Values.Data;
    iq_ref = logs.get('iq_ref').Values.Data;
    id_act = logs.get('id_actual').Values.Data;
    iq_act = logs.get('iq_actual').Values.Data;
    
    fprintf('Final Speed reached: %.1f RPM (Reference: 18000 RPM)\n', spd(end));
    fprintf('Max Speed reached: %.1f RPM\n', max(spd));
    fprintf('id_ref min/max: %.2f / %.2f A\n', min(id_ref), max(id_ref));
    fprintf('iq_ref min/max: %.2f / %.2f A\n', min(iq_ref), max(iq_ref));
    fprintf('id_act min/max: %.2f / %.2f A\n', min(id_act), max(id_act));
    fprintf('iq_act min/max: %.2f / %.2f A\n', min(iq_act), max(iq_act));
    
    % Check for instability / overshoot / oscillation
    fprintf('Speed at t=0.10s: %.1f RPM\n', interp1(t, spd, 0.10));
    fprintf('Speed at t=0.15s: %.1f RPM\n', interp1(t, spd, 0.15));
    fprintf('Speed at t=0.20s: %.1f RPM\n', interp1(t, spd, 0.20));
catch ME
    fprintf('Simulation failed with error: %s\n', ME.message);
end
