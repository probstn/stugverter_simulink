%% run_hil.m
% =========================================================================
% HARDWARE-IN-THE-LOOP (HIL) SIMULATION SCRIPT
% =========================================================================
% Simulates the Fischer IPMSM motor plant and EVADC sampling in Simulink,
% transmits 12-bit ADC counts & speed setpoint to the AURIX TC387 over
% XCP UDP STIM in lockstep, receives computed PWM duty cycles over
% XCP UDP DAQ, and opens verification plots directly for investigation.

fprintf('\n================================================================\n');
fprintf(' [HIL] Starting Hardware-in-the-Loop Simulation (TC387 + XCP)...\n');
fprintf('================================================================\n');

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

projectRoot = fileparts(simulinkDir);
scriptsDir  = fullfile(simulinkDir, 'scripts');
modelsDir   = fullfile(simulinkDir, 'models');

if isfolder(scriptsDir), addpath(scriptsDir); end
if isfolder(modelsDir),  addpath(modelsDir);  end

% Suppress shadowing warning
warning('off', 'Simulink:Engine:MdlFileShadowedByFile');

modelName = 'stugverter';
if ~exist('foc', 'var') || ~isfield(foc, 'simStopTime')
    if evalin('base', 'exist(''foc'', ''var'')')
        foc = evalin('base', 'foc');
        pmsm = evalin('base', 'pmsm');
    else
        run(fullfile(simulinkDir, 'scripts', 'init.m'));
    end
end

if ~bdIsLoaded(modelName)
    load_system(fullfile(modelsDir, [modelName '.slx']));
end

% 1. Verify Target MCU connectivity via winIDEA Python API
fprintf('Checking Infineon AURIX TC387 status via winIDEA...\n');
winideaPython = 'C:\winIDEA\Python\python.exe';
if ~exist(winideaPython, 'file'), winideaPython = 'python'; end

pyCheckCode = sprintf([ ...
    'import isystem.connect as ic, sys\n', ...
    'try:\n', ...
    '    cm = ic.ConnectionMgr()\n', ...
    '    cm.connectMRU("")\n', ...
    '    exec_ctrl = ic.CExecutionController(cm)\n', ...
    '    debug_ctrl = ic.CDebugFacade(cm)\n', ...
    '    st = exec_ctrl.getCPUStatus()\n', ...
    '    if not st.isRunning():\n', ...
    '        exec_ctrl.run()\n', ...
    '    isr = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_foc_isr_counter")\n', ...
    '    us = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_foc_exec_time_us")\n', ...
    '    debug_ctrl.modify(ic.IConnectDebug.fMonitor, "g_hil_mode_enable", "0")\n', ...
    '    print(f"TARGET_OK: Running={st.isRunning()}, ISR={isr.getInt()}, ExecTime={us.getFloat():.2f}us (HIL reset to 0)")\n', ...
    'except Exception as e:\n', ...
    '    print(f"TARGET_CHECK_WARNING: {e}", file=sys.stderr)\n' ...
]);

pyCheckFile = fullfile(tempdir, 'check_target.py');
fid = fopen(pyCheckFile, 'w');
if fid ~= -1
    fwrite(fid, pyCheckCode);
    fclose(fid);
    [pyStatus, pyOut] = system(sprintf('"%s" "%s"', winideaPython, pyCheckFile));
    if exist(pyCheckFile, 'file'), delete(pyCheckFile); end
    if pyStatus == 0 && contains(pyOut, 'TARGET_OK:')
        fprintf('  %s\n', strtrim(pyOut));
    else
        error('winIDEA target check failed: %s', strtrim(pyOut));
    end
end

% 2. Configure Model for HIL Execution
fprintf('Configuring %s for HIL operation...\n', modelName);
set_param('stugverter/Processor/HIL_Switch', 'sw', '0'); % 0 = HIL (AURIX TC387 over XCP UDP)
% The Windows XCP master, Ethernet target, and Simscape plant run slower than
% wall-clock real time on this host. Pacing keeps the exchange orderly while
% preserving the controller's 50 us simulated sample time.
set_param(modelName, 'EnablePacing', 'on', 'PacingRate', foc.hilPacingRate);
set_param(modelName, 'StopTime', num2str(foc.simStopTime));

% 3. Open Live Speed Scope BEFORE starting simulation
fprintf('Opening live rotor speed tracking scope...\n');
try
    open_system('stugverter/Processor/Scope_Speed');
    drawnow;
catch
end

% 4. Run HIL Simulation
fprintf('Simulating %s for StopTime = %.2f s (Real-Time Paced)...\n', modelName, foc.simStopTime);
tic;
simOut = sim(modelName);
hilElapsed = toc;
fprintf('HIL simulation completed in %.2f s.\n', hilElapsed);

% Set g_hil_mode_enable back to 0 on target after simulation ends
try
    pyResetCode = sprintf('import isystem.connect as ic\ncm = ic.ConnectionMgr()\ncm.connectMRU("")\nic.CDebugFacade(cm).modify(ic.IConnectDebug.fMonitor, "g_hil_mode_enable", "0")\n');
    pyResetFile = fullfile(tempdir, 'reset_hil.py');
    fid = fopen(pyResetFile, 'w');
    if fid ~= -1
        fwrite(fid, pyResetCode); fclose(fid);
        system(sprintf('"%s" "%s"', winideaPython, pyResetFile));
        if exist(pyResetFile, 'file'), delete(pyResetFile); end
    end
catch
end

% 4. Extract HIL Telemetry and Signals
logs = simOut.logsout;
getSignal = @(logsObj, name) (logsObj.get(name).Values);
hasScopeSpeed = isprop(simOut, 'scope_speed') || isfield(simOut, 'scope_speed');
if hasScopeSpeed && ~isempty(simOut.scope_speed)
    spData = simOut.scope_speed{1}.Values;
    t_spd    = spData.Time;
    rpm_ref  = spData.Data(:, 1);
    rpm_meas = spData.Data(:, 2);
else
    try
        spd_ref  = getSignal(logs, 'spd_ref_rads');
        spd_meas = getSignal(logs, 'spd_meas_rads');
        t_spd    = spd_meas.Time;
        rpm_ref  = spd_ref.Data  * (30 / pi);
        rpm_meas = spd_meas.Data * (30 / pi);
    catch ME
        error('Could not extract speed signals from logsout or scope_speed: %s', ME.message);
    end
end

% Extract explicitly logged parallel SIL/HIL controller outputs.
try
    dutySignal = getSignal(logs, 'duty_hil_raw');
    t_duty = dutySignal.Time;
    duty_hil = dutySignal.Data;
    duty_sil_parallel = getSignal(logs, 'duty_sil_parallel').Data;
catch
    t_duty = t_spd;
    duty_hil = repmat([0.5, 0.5, 0.5], length(t_duty), 1);
    duty_sil_parallel = [];
end

% Extract ADC signals
hasAdc = isprop(simOut, 'scope_adc_signals') || isfield(simOut, 'scope_adc_signals');
if hasAdc && ~isempty(simOut.scope_adc_signals)
    adcVals = simOut.scope_adc_signals{1}.Values;
    t_adc = adcVals.ia.Time;
    ia_counts = adcVals.ia.Data;
    ib_counts = adcVals.ib.Data;
    ic_counts = adcVals.ic.Data;
else
    t_adc = t_spd;
    ia_counts = zeros(size(t_adc));
    ib_counts = zeros(size(t_adc));
    ic_counts = zeros(size(t_adc));
end

% Extract Hardware Telemetry (ISR count, execution time)
hasTelem = isprop(simOut, 'scope_hw_telemetry') || isfield(simOut, 'scope_hw_telemetry');
if hasTelem && ~isempty(simOut.scope_hw_telemetry)
    t_telem = simOut.scope_hw_telemetry{1}.Values.Time;
    telemData = simOut.scope_hw_telemetry{1}.Values.Data;
    isr_counts = telemData(:, 1);
    exec_times = telemData(:, 2);
else
    t_telem = t_spd;
    isr_counts = zeros(size(t_telem));
    exec_times = zeros(size(t_telem));
end

% 5. Print HIL Performance Summary
max_rpm_meas = max(rpm_meas);
final_rpm_meas = rpm_meas(end);
final_rpm_ref = rpm_ref(end);
avg_exec_us = mean(exec_times(exec_times > 0));

fprintf('\n------------------- HIL PERFORMANCE SUMMARY --------------------\n');
fprintf('  Max Speed Target:          %10.1f RPM\n', max(rpm_ref));
fprintf('  Max Speed Reached:         %10.1f RPM\n', max_rpm_meas);
fprintf('  Final Speed Target:        %10.1f RPM\n', final_rpm_ref);
fprintf('  Final Speed Reached:       %10.1f RPM (Error: %.2f RPM)\n', final_rpm_meas, abs(final_rpm_meas - final_rpm_ref));
if ~isnan(avg_exec_us) && avg_exec_us > 0
    fprintf('  Average AURIX Execution:   %10.2f us (FOC budget: %.1f us)\n', avg_exec_us, foc.Ts*1e6);
end
if ~isempty(duty_sil_parallel)
    bestDutyRms = inf;
    bestDutyLag = 0;
    for lag = 0:10
        dutyError = duty_hil(1+lag:end, :) - duty_sil_parallel(1:end-lag, :);
        dutyRms = sqrt(mean(dutyError(:).^2));
        if dutyRms < bestDutyRms
            bestDutyRms = dutyRms;
            bestDutyLag = lag;
        end
    end
    fprintf('  SIL/HIL PWM RMS Difference:%10.5f (aligned by %d sample(s))\n', bestDutyRms, bestDutyLag);
end
fprintf('----------------------------------------------------------------\n\n');

% 6. Extract Motor dq Currents if available
hasIdRef = false;
try
    id_act = getSignal(logs, 'id_actual');
    iq_act = getSignal(logs, 'iq_actual');
    hasIdAct = true;
    try
        id_ref_eff = getSignal(logs, 'id_ref_effective');
        iq_ref     = getSignal(logs, 'iq_ref');
        hasIdRef   = true;
    catch
        hasIdRef   = false;
    end
catch
    hasIdAct = false;
end

% 7. Figure 1: Time-Domain Dynamic Performance & Hardware Telemetry
fig1 = figure('Name', 'Stugverter HIL Algorithm Verification: Time-Domain & Telemetry', 'NumberTitle', 'off', 'Color', 'w');
set(fig1, 'Position', [60, 60, 880, 850], 'Visible', 'on');

% Panel 1: Speed Tracking
subplot(3, 1, 1);
plot(t_spd, rpm_ref, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Reference (RPM)');
hold on;
plot(t_spd, rpm_meas, 'Color', [0.85, 0.2, 0.1], 'LineWidth', 1.5, 'DisplayName', 'HIL Measured (RPM)');
yline(pmsm.N_base, 'b:', 'LineWidth', 1.2, 'DisplayName', sprintf('Base Speed (%.0f RPM)', pmsm.N_base));
grid on;
title('AURIX TC387 HIL: Rotor Mechanical Speed Tracking');
xlabel('Time [s]');
ylabel('Speed [RPM]');
legend('Location', 'best');

% Panel 2: PWM Duty Cycles Received via XCP DAQ
subplot(3, 1, 2);
plot(t_duty, duty_hil(:, 1), 'r-', 'LineWidth', 1.2, 'DisplayName', 'Duty U (AURIX)');
hold on;
plot(t_duty, duty_hil(:, 2), 'g-', 'LineWidth', 1.2, 'DisplayName', 'Duty V (AURIX)');
plot(t_duty, duty_hil(:, 3), 'b-', 'LineWidth', 1.2, 'DisplayName', 'Duty W (AURIX)');
grid on;
title('Inverter Phase Duty Cycles Received from AURIX TC387 (XCP UDP DAQ)');
xlabel('Time [s]');
ylabel('Duty [0-1]');
legend('Location', 'best');

% Panel 3: Hardware Telemetry
subplot(3, 1, 3);
yyaxis left;
plot(t_telem, isr_counts, 'b-', 'LineWidth', 1.2, 'DisplayName', 'FOC ISR Count');
ylabel('ISR Execution Count');
yyaxis right;
plot(t_telem, exec_times, 'm-', 'LineWidth', 1.2, 'DisplayName', 'FOC Core Exec Time [us]');
ylabel('Exec Time [\mus]');
yline(foc.Ts*1e6, 'r--', 'DisplayName', sprintf('20 kHz Budget (%.0f us)', foc.Ts*1e6));
grid on;
title('Target Telemetry: FOC ISR Counter & Core Execution Time');
xlabel('Time [s]');

% 8. Figure 2: id vs. iq Vector Plane (MTPA Curve, Limit Curves, and Setpoints)
if hasIdAct
    fig2 = figure('Name', 'Stugverter HIL Current Plane (id vs. iq): MTPA, Limits & Trajectory', ...
                  'NumberTitle', 'off', 'Color', 'w');
    set(fig2, 'Position', [960, 60, 850, 850], 'Visible', 'on');
    hold on; grid on; box on;

    Ld = pmsm.Ld;
    Lq = pmsm.Lq;
    fl = pmsm.fl;
    Imax = pmsm.I_rated;
    Vmax = foc.V_phase_max;
    P = pmsm.P;
    deltaL = Lq - Ld;

    % Current Limit Circle
    theta_circ = linspace(0, 2*pi, 400);
    plot(Imax * cos(theta_circ), Imax * sin(theta_circ), 'r-', 'LineWidth', 2.0, ...
         'DisplayName', sprintf('Current Limit Circle (I_{rated} = %.1f A)', Imax));

    % Voltage Limit Ellipses at key operating speeds
    center_id = -fl / Ld;
    speeds_rpm = [pmsm.N_base, 14000, 18000];
    colors_volt = [0.85 0.35 0.05; 0.65 0.15 0.65; 0.75 0.05 0.15];
    styles_volt = {':', '--', '-'};

    for idx = 1:length(speeds_rpm)
        N_test = speeds_rpm(idx);
        we = P * (2 * pi * N_test / 60);
        a_d = Vmax / (we * Ld);
        b_q = Vmax / (we * Lq);
        
        id_ell = center_id + a_d * cos(theta_circ);
        iq_ell = b_q * sin(theta_circ);
        
        plot(id_ell, iq_ell, 'Color', colors_volt(idx, :), 'LineWidth', 1.4, ...
             'LineStyle', styles_volt{idx}, ...
             'DisplayName', sprintf('Voltage Limit @ %5.0f RPM', N_test));
    end

    % Theoretical MTPA Curve
    Is_vec = linspace(0, Imax, 250);
    sin_beta = (-fl + sqrt(fl^2 + 8 * deltaL^2 * Is_vec.^2)) ./ (4 * deltaL * Is_vec);
    sin_beta(1) = 0;
    id_mtpa_pos = -Is_vec .* sin_beta;
    iq_mtpa_pos = Is_vec .* sqrt(max(0, 1 - sin_beta.^2));
    id_mtpa = [flip(id_mtpa_pos), id_mtpa_pos];
    iq_mtpa = [flip(-iq_mtpa_pos), iq_mtpa_pos];

    plot(id_mtpa, iq_mtpa, 'Color', [0.1 0.55 0.1], 'LineWidth', 2.2, ...
         'DisplayName', 'Theoretical MTPA Curve');

    % Commanded Setpoints if available
    if hasIdRef
        plot(id_ref_eff.Data, iq_ref.Data, 'b--', 'LineWidth', 1.6, ...
             'DisplayName', 'Commanded Setpoints (i_{d,eff}^*, i_q^*)');
    end

    % Actual Measured Current Trajectory from HIL execution
    plot(id_act.Data, iq_act.Data, 'Color', [0.95 0.5 0.0], 'LineWidth', 1.4, ...
         'DisplayName', 'HIL Actual Measured (i_d, i_q)');

    % Voltage ellipse center marker
    plot(center_id, 0, 'kx', 'MarkerSize', 10, 'LineWidth', 2, ...
         'DisplayName', sprintf('Ellipse Center (-\\psi_m/L_d = %.1f A)', center_id));

    xlabel('d-axis Current i_d [A]', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('q-axis Current i_q [A]', 'FontSize', 11, 'FontWeight', 'bold');
    title('AURIX TC387 HIL: i_d vs. i_q Trajectory on MTPA & Limit Curves', 'FontSize', 12, 'FontWeight', 'bold');

    axis equal;
    xlim([-115, 35]);
    ylim([-95, 95]);
    xline(0, 'k:');
    yline(0, 'k:');
    legend('Location', 'eastoutside', 'FontSize', 9);
end

drawnow;
fprintf('[+] HIL verification plots and scopes opened directly for investigation.\n');
