%% run_simulation.m
% =========================================================================
% STUGVERTER SIL SIMULATION & RESULT INSPECTION
% =========================================================================
% Runs the SIL controller variant in stugverter_sim.slx.
% opens live scopes before simulation starts, verifies motor control
% performance (MTPA + Field Weakening), and displays interactive results
% including time-domain tracking and the id vs. iq vector plane.

warning('off', 'Simulink:Engine:MdlFileShadowedByFile');

fprintf('\n================================================================\n');
fprintf(' [SIMULATION] Running SIL Variant (stugverter_sim.slx)...\n');
fprintf('================================================================\n');

% 1. Setup paths
if exist('resolve_simulink_dir', 'file') == 2
    simulinkDir = resolve_simulink_dir();
else
    try
        proj = currentProject;
        simulinkDir = proj.RootFolder;
    catch
        candidates = {pwd, fullfile(pwd, 'simulink'), fileparts(pwd), ...
                      fullfile(fileparts(pwd), 'simulink'), ...
                      'C:\Users\probst\Desktop\stugverter\simulink'};
        simulinkDir = pwd;
        for k = 1:length(candidates)
            if exist(fullfile(candidates{k}, 'scripts', 'init.m'), 'file')
                simulinkDir = candidates{k};
                break;
            end
        end
    end
end

if ~exist(fullfile(simulinkDir, 'scripts', 'init.m'), 'file')
    simulinkDir = fileparts(fileparts(mfilename('fullpath')));
end

scriptsDir = fullfile(simulinkDir, 'scripts');
modelsDir  = fullfile(simulinkDir, 'models');
if isfolder(scriptsDir), addpath(scriptsDir); end
if isfolder(modelsDir),  addpath(modelsDir);  end

% 2. Ensure workspace variables and model are loaded
modelName = 'stugverter_sim';
if ~exist('foc', 'var') || ~isfield(foc, 'simStopTime')
    if evalin('base', 'exist(''foc'', ''var'')')
        foc = evalin('base', 'foc');
        pmsm = evalin('base', 'pmsm');
    else
        run(fullfile(simulinkDir, 'scripts', 'init.m'));
    end
end

% Explicit test command. Production/code-generation defaults remain OFF.
control_enable_request.Value = true;
% Default demo uses SPEED mode. Modes: 1=TORQUE, 2=SPEED, 3=OPEN LOOP.
control_mode_request.Value = uint8(2);
calibration_request.Value = uint8(0);
simulation_mode.Value = uint8(0);
assignin('base', 'control_enable_request', control_enable_request);
assignin('base', 'control_mode_request', control_mode_request);
assignin('base', 'calibration_request', calibration_request);
assignin('base', 'simulation_mode', simulation_mode);

if ~bdIsLoaded(modelName)
    load_system(fullfile(modelsDir, [modelName '.slx']));
end

% 3. Open Live Speed Scope BEFORE starting simulation
fprintf('Opening live rotor speed tracking scope...\n');
try
    open_system([modelName '/Processor/Logging/Speed']);
    drawnow;
catch
end

% 4. Run simulation
fprintf('Simulating %s for StopTime = %.2f s...\n', modelName, foc.simStopTime);
tic;
simIn = Simulink.SimulationInput(modelName);
simIn = setModelParameter(simIn, 'StopTime', num2str(foc.simStopTime), ...
    'EnablePacing', 'off');
simOut = sim(simIn);
elapsed = toc;
fprintf('Simulation completed in %.2f s.\n', elapsed);

% 5. Extract logged signals from logsout
logs = simOut.logsout;
getSignal = @(logsObj, name) (logsObj.get(name).Values);

try
    spd_ref    = getSignal(logs, 'spd_ref_rads');
    spd_meas   = getSignal(logs, 'spd_meas_rads');
    id_ref_eff = getSignal(logs, 'id_ref_effective');
    id_act     = getSignal(logs, 'id_actual');
    iq_ref     = getSignal(logs, 'iq_ref');
    iq_act     = getSignal(logs, 'iq_actual');
    Vd_cmd     = getSignal(logs, 'Vd_cmd');
    Vq_cmd     = getSignal(logs, 'Vq_cmd');
catch ME
    error('Could not extract required logged signals from simOut.logsout: %s', ME.message);
end

t = spd_meas.Time;
rpm_ref  = spd_ref.Data  * (30 / pi);
rpm_meas = spd_meas.Data * (30 / pi);
V_mag    = sqrt(Vd_cmd.Data.^2 + Vq_cmd.Data.^2);

% 6. Performance Summary & Assertions
max_rpm_ref    = max(rpm_ref);
max_rpm_meas   = max(rpm_meas);
final_rpm_ref  = rpm_ref(end);
final_rpm_meas = rpm_meas(end);
min_id_act     = min(id_act.Data);
min_id_eff     = min(id_ref_eff.Data);
max_id_err     = max(abs(id_act.Data - id_ref_eff.Data));
max_iq_err     = max(abs(iq_act.Data - iq_ref.Data));
max_V_mag      = max(V_mag);

fprintf('\n------------------- SIL PERFORMANCE SUMMARY --------------------\n');
fprintf('  Max Speed Target:          %10.1f RPM\n', max_rpm_ref);
fprintf('  Max Speed Reached:         %10.1f RPM (Error: %.2f RPM)\n', max_rpm_meas, abs(max_rpm_meas - max_rpm_ref));
fprintf('  Final Speed Target:        %10.1f RPM\n', final_rpm_ref);
fprintf('  Final Speed Reached:       %10.1f RPM (Error: %.2f RPM)\n', final_rpm_meas, abs(final_rpm_meas - final_rpm_ref));
fprintf('  Field Weakening Min Id:    %10.2f A (Target: %.2f A)\n', min_id_act, min_id_eff);
fprintf('  Max Absolute Id Error:     %10.2f A\n', max_id_err);
fprintf('  Max Absolute Iq Error:     %10.2f A\n', max_iq_err);
fprintf('  Peak Stator Phase Voltage: %10.2f V (Phase limit: %.2f V)\n', max_V_mag, foc.V_phase_max);
fprintf('----------------------------------------------------------------\n');

assert(max_rpm_meas > 0.90 * max_rpm_ref, ...
    'Motor failed to reach 90%% of the low-voltage target speed.');
assert(abs(final_rpm_meas - final_rpm_ref) < max(20, 0.05 * abs(final_rpm_ref)), ...
    'Final speed tracking error exceeds the commissioning limit.');
fprintf('>>> All SIL performance criteria satisfied! <<<\n\n');

% 7. Figure 1: Time-Domain Dynamic Performance
fig1 = figure('Name', 'Stugverter SIL Simulation Results: Time-Domain Tracking', 'NumberTitle', 'off', 'Color', 'w');
set(fig1, 'Position', [60, 80, 880, 720], 'Visible', 'on');

% Subplot 1: Speed Tracking
subplot(3, 1, 1);
plot(t, rpm_ref, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Reference (RPM)');
hold on;
plot(t, rpm_meas, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Measured (RPM)');
yline(pmsm.N_base, 'r:', 'LineWidth', 1.2, 'DisplayName', sprintf('Base Speed (%.0f RPM)', pmsm.N_base));
grid on;
title('Rotor Mechanical Speed Tracking (MTPA & Field Weakening)');
xlabel('Time [s]');
ylabel('Speed [RPM]');
legend('Location', 'best');

% Subplot 2: dq Currents
subplot(3, 1, 2);
plot(t, id_ref_eff.Data, 'b--', 'LineWidth', 1.2, 'DisplayName', 'i_d Effective Ref');
hold on;
plot(t, id_act.Data, 'b-', 'LineWidth', 1.2, 'DisplayName', 'i_d Actual');
plot(t, iq_ref.Data, 'r--', 'LineWidth', 1.2, 'DisplayName', 'i_q Ref');
plot(t, iq_act.Data, 'r-', 'LineWidth', 1.2, 'DisplayName', 'i_q Actual');
grid on;
title('Stator dq-axis Currents (Demagnetizing i_d & Torque i_q)');
xlabel('Time [s]');
ylabel('Current [A]');
legend('Location', 'best');

% Subplot 3: Phase Voltage Magnitude
subplot(3, 1, 3);
plot(t, V_mag, 'Color', [0.1 0.6 0.1], 'LineWidth', 1.5, 'DisplayName', '|V_{dq}| Commanded');
hold on;
yline(foc.V_phase_max, 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('V_{phase,max} Limit (%.1f V)', foc.V_phase_max));
grid on;
title('Stator Phase Voltage Magnitude vs. Inverter Limit');
xlabel('Time [s]');
ylabel('Voltage [V]');
legend('Location', 'best');

% 8. Figure 2: id vs. iq Vector Plane (MTPA Curve, Limit Curves, and Setpoints)
fig2 = figure('Name', 'Stugverter FOC Current Plane (id vs. iq): MTPA, Limits & Setpoints', ...
              'NumberTitle', 'off', 'Color', 'w');
set(fig2, 'Position', [960, 80, 850, 720], 'Visible', 'on');
hold on; grid on; box on;

% Parameters for vector diagram
Ld = pmsm.Ld;
Lq = pmsm.Lq;
fl = pmsm.fl;
Imax = pmsm.I_rated;
Vmax = foc.V_phase_max;
P = pmsm.P;
deltaL = Lq - Ld;

% Current Limit Circle (id^2 + iq^2 = Imax^2)
theta_circ = linspace(0, 2*pi, 400);
plot(Imax * cos(theta_circ), Imax * sin(theta_circ), 'r-', 'LineWidth', 2.0, ...
     'DisplayName', sprintf('Current Limit Circle (I_{rated} = %.1f A)', Imax));

% Voltage Limit Ellipses at key operating speeds
center_id = -fl / Ld;
speeds_rpm = [pmsm.N_base, 0.85*pmsm.N_max, pmsm.N_max];
colors_volt = [0.85 0.35 0.05; 0.65 0.15 0.65; 0.75 0.05 0.15];
styles_volt = {':', '--', '-'};

for idx = 1:length(speeds_rpm)
    N_test = speeds_rpm(idx);
    we = P * (2 * pi * N_test / 60);
    a_d = Vmax / (we * Ld);  % d-axis semi-axis
    b_q = Vmax / (we * Lq);  % q-axis semi-axis
    
    id_ell = center_id + a_d * cos(theta_circ);
    iq_ell = b_q * sin(theta_circ);
    
    plot(id_ell, iq_ell, 'Color', colors_volt(idx, :), 'LineWidth', 1.4, ...
         'LineStyle', styles_volt{idx}, ...
         'DisplayName', sprintf('Voltage Limit @ %5.0f RPM', N_test));
end

% Theoretical MTPA Curve (Maximum Torque Per Ampere)
Is_vec = linspace(0, Imax, 250);
sin_beta = (-fl + sqrt(fl^2 + 8 * deltaL^2 * Is_vec.^2)) ./ (4 * deltaL * Is_vec);
sin_beta(1) = 0; % limit as Is -> 0
id_mtpa_pos = -Is_vec .* sin_beta;
iq_mtpa_pos = Is_vec .* sqrt(max(0, 1 - sin_beta.^2));

% Full MTPA curve covering both motoring and braking
id_mtpa = [flip(id_mtpa_pos), id_mtpa_pos];
iq_mtpa = [flip(-iq_mtpa_pos), iq_mtpa_pos];

plot(id_mtpa, iq_mtpa, 'Color', [0.1 0.55 0.1], 'LineWidth', 2.2, ...
     'DisplayName', 'Theoretical MTPA Curve');

% Commanded Setpoints Trajectory (id_ref_effective vs. iq_ref)
plot(id_ref_eff.Data, iq_ref.Data, 'b--', 'LineWidth', 1.6, ...
     'DisplayName', 'Commanded Setpoints (i_{d,eff}^*, i_q^*)');

% Key regime setpoint transition markers
t_marks = [0.05, 0.25, 0.45, 0.80];
labels_marks = {'0 RPM (Rest)', '8k RPM (MTPA)', '18k RPM (Deep FW)', '6k RPM (Return)'};
mark_colors = {'k', [0.1 0.6 0.1], [0.8 0.1 0.1], [0.1 0.3 0.8]};

for m = 1:length(t_marks)
    [~, idx_m] = min(abs(t - t_marks(m)));
    plot(id_ref_eff.Data(idx_m), iq_ref.Data(idx_m), 'o', 'MarkerSize', 8, ...
         'MarkerFaceColor', mark_colors{m}, 'MarkerEdgeColor', 'k', ...
         'DisplayName', sprintf('Setpoint: %s', labels_marks{m}));
end

% Actual Measured Current Trajectory (id_actual vs. iq_actual)
plot(id_act.Data, iq_act.Data, 'Color', [0.95 0.5 0.0], 'LineWidth', 1.2, ...
     'DisplayName', 'Actual Measured (i_d, i_q)');

% Voltage ellipse center marker
plot(center_id, 0, 'kx', 'MarkerSize', 10, 'LineWidth', 2, ...
     'DisplayName', sprintf('Ellipse Center (-\\psi_m/L_d = %.1f A)', center_id));

% Diagram layout & labels
xlabel('d-axis Current i_d [A]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('q-axis Current i_q [A]', 'FontSize', 11, 'FontWeight', 'bold');
title('IPMSM FOC State Space: i_d vs. i_q with MTPA & Limit Curves', 'FontSize', 12, 'FontWeight', 'bold');

axis equal;
xlim([-115, 35]);
ylim([-95, 95]);
xline(0, 'k:');
yline(0, 'k:');
legend('Location', 'eastoutside', 'FontSize', 9);

drawnow;
fprintf('[+] Figures and scopes opened directly for investigation.\n');
