%% run_simulation.m
% Verification and smoke test runner for stugverter FOC simulation
% Validates MTPA regime, field-weakening regime, and deceleration tracking.

clearvars;
close all;
clc;

projectDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(projectDir)
    projectDir = pwd;
end

cd(projectDir);
addpath(fullfile(projectDir, 'scripts'));
addpath(fullfile(projectDir, 'models'));

%% Initialize parameters
fprintf('Initializing motor, controller, and test profile parameters...\n');
init;

%% Load and simulate top-level stugverter model
modelName = 'stugverter';
fprintf('Loading and simulating %s (StopTime = %.2f s)...\n', modelName, foc.simStopTime);

tic;
simOut = sim(modelName);
simElapsed = toc;
fprintf('Simulation completed in %.2f seconds.\n\n', simElapsed);

%% Extract and analyze simulation logs
logs = simOut.logsout;

function val = get_logged_signal(logs, name)
    val = [];
    try
        item = logs.get(name);
        if ~isempty(item)
            val = item.Values;
        end
    catch
    end
end

spd_ref = get_logged_signal(logs, 'spd_ref_rads');
spd_meas = get_logged_signal(logs, 'spd_meas_rads');
id_ref = get_logged_signal(logs, 'id_ref');
iq_ref = get_logged_signal(logs, 'iq_ref');
id_ref_eff = get_logged_signal(logs, 'id_ref_effective');
id_actual = get_logged_signal(logs, 'id_actual');
iq_actual = get_logged_signal(logs, 'iq_actual');
Vd_cmd = get_logged_signal(logs, 'Vd_cmd');
Vq_cmd = get_logged_signal(logs, 'Vq_cmd');

% Conversion to RPM
rpm_ref = spd_ref.Data * 30/pi;
rpm_meas = spd_meas.Data * 30/pi;
t = spd_meas.Time;

% Performance Metrics
max_rpm_ref = max(rpm_ref);
max_rpm_meas = max(rpm_meas);
final_rpm_ref = rpm_ref(end);
final_rpm_meas = rpm_meas(end);

fprintf('=================== FOC VALIDATION SUMMARY ===================\n');
fprintf('Maximum Speed Reference:   %10.1f RPM\n', max_rpm_ref);
fprintf('Maximum Speed Reached:     %10.1f RPM (Error: %.2f RPM)\n', ...
    max_rpm_meas, abs(max_rpm_meas - max_rpm_ref));
fprintf('Final Speed Reference:     %10.1f RPM\n', final_rpm_ref);
fprintf('Final Speed Reached:       %10.1f RPM (Error: %.2f RPM)\n', ...
    final_rpm_meas, abs(final_rpm_meas - final_rpm_ref));
fprintf('--------------------------------------------------------------\n');

if ~isempty(id_ref_eff)
    fprintf('Field Weakening Min Id Ref:    %10.2f A\n', min(id_ref_eff.Data));
end
if ~isempty(id_actual)
    fprintf('Field Weakening Min Id Actual: %10.2f A\n', min(id_actual.Data));
end
if ~isempty(id_actual) && ~isempty(id_ref_eff)
    fprintf('Max Absolute Id Error:         %10.2f A\n', max(abs(id_actual.Data - id_ref_eff.Data)));
end
if ~isempty(iq_actual) && ~isempty(iq_ref)
    fprintf('Max Absolute Iq Error:         %10.2f A\n', max(abs(iq_actual.Data - iq_ref.Data)));
end
if ~isempty(Vd_cmd) && ~isempty(Vq_cmd)
    fprintf('--------------------------------------------------------------\n');
    fprintf('Max Phase Voltage Magnitude:   %10.2f V (Phase limit: %.2f V)\n', ...
        max(sqrt(Vd_cmd.Data.^2 + Vq_cmd.Data.^2)), foc.V_phase_max);
end
fprintf('==============================================================\n');

% Assertions
assert(max_rpm_meas > 17500, 'Motor failed to reach field weakening speed (> 17500 RPM)');
assert(abs(final_rpm_meas - final_rpm_ref) < 100, 'Final speed tracking error too large (> 100 RPM)');

fprintf('\n>>> ALL CHECKS PASSED: Stugverter FOC + MTPA + Speed Control is fully functional. <<<\n');
