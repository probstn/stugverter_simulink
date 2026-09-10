%% step7_compare_sil_hil.m
% =========================================================================
% SIL / HIL EQUIVALENCE VERIFICATION (FAST COMPARISON WITHOUT RE-RUNNING)
% =========================================================================
% Compares physical plant rotor speed and PWM duty cycles between the
% previous SIL simulation (step1_run_sil.m) and AURIX TC387 HIL execution
% (step6_run_hil.m) on a common 50 us time grid.

fprintf('\n================================================================\n');
fprintf(' [VALIDATE] Comparing Previous SIL and AURIX TC387 HIL Results...\n');
fprintf('================================================================\n');

if exist('resolve_simulink_dir', 'file') == 2
    simulinkDir = resolve_simulink_dir();
else
    simulinkDir = fileparts(fileparts(mfilename('fullpath')));
end

% 1. Ensure initialization and parameters
if ~exist('foc', 'var') || ~isfield(foc, 'simStopTime')
    if evalin('base', 'exist(''foc'', ''var'')')
        foc = evalin('base', 'foc');
        pmsm = evalin('base', 'pmsm');
    else
        run(fullfile(simulinkDir, 'scripts', 'init.m'));
    end
end

% 2. Retrieve SIL Results
silDataFile = fullfile(simulinkDir, 'sil_results.mat');
silLoaded = false;
if evalin('base', 'exist(''silOut'', ''var'')')
    silOut = evalin('base', 'silOut');
    if isprop(silOut, 'scope_speed') || isfield(silOut, 'scope_speed')
        silSpeed = silOut.scope_speed{1}.Values;
        silLoaded = true;
    end
end
if ~silLoaded && exist(silDataFile, 'file')
    data = load(silDataFile);
    if isfield(data, 'simOut') && (isprop(data.simOut, 'scope_speed') || isfield(data.simOut, 'scope_speed'))
        silOut = data.simOut;
        silSpeed = silOut.scope_speed{1}.Values;
        silLoaded = true;
    elseif isfield(data, 'rpm_meas') && isfield(data, 't')
        silSpeed.Time = data.t;
        silSpeed.Data = [data.rpm_ref, data.rpm_meas];
        silLoaded = true;
    end
end

if ~silLoaded
    error(['SIL simulation results not found!\n', ...
           'Please run Step 1 (step1_run_sil.m) first to generate SIL results before comparing.'], '');
end

% 3. Retrieve HIL Results
hilDataFile = fullfile(simulinkDir, 'hil_results.mat');
hilLoaded = false;
if evalin('base', 'exist(''hilOut'', ''var'')')
    hilOut = evalin('base', 'hilOut');
    if isprop(hilOut, 'scope_speed') || isfield(hilOut, 'scope_speed')
        hilSpeed = hilOut.scope_speed{1}.Values;
        hilLoaded = true;
    end
end
if ~hilLoaded && exist(hilDataFile, 'file')
    data = load(hilDataFile);
    if isfield(data, 'simOut') && (isprop(data.simOut, 'scope_speed') || isfield(data.simOut, 'scope_speed'))
        hilOut = data.simOut;
        hilSpeed = hilOut.scope_speed{1}.Values;
        hilLoaded = true;
    elseif isfield(data, 'rpm_meas') && isfield(data, 't_spd')
        hilSpeed.Time = data.t_spd;
        hilSpeed.Data = [data.rpm_ref, data.rpm_meas];
        hilLoaded = true;
    end
end

if ~hilLoaded
    error(['HIL simulation results not found!\n', ...
           'Please run Step 6 (step6_run_hil.m) first to generate HIL results before comparing.'], '');
end

fprintf('Loaded SIL results (%d samples) and HIL results (%d samples).\n', ...
    length(silSpeed.Time), length(hilSpeed.Time));

% 4. Interpolate onto common 50 us simulation grid
t_max = min([silSpeed.Time(end), hilSpeed.Time(end), foc.simStopTime]);
sampleGrid = (0:foc.Ts:t_max).';

silRpm = interp1(silSpeed.Time, silSpeed.Data(:, 2), sampleGrid, 'linear');
hilRpm = interp1(hilSpeed.Time, hilSpeed.Data(:, 2), sampleGrid, 'linear');
refRpm = interp1(silSpeed.Time, silSpeed.Data(:, 1), sampleGrid, 'linear');

speed_diff = hilRpm - silRpm;

metrics.speed_rmse_rpm            = sqrt(mean(speed_diff.^2));
metrics.speed_max_abs_rpm         = max(abs(speed_diff));
metrics.peak_speed_difference_rpm = max(hilRpm) - max(silRpm);
metrics.final_speed_difference_rpm = hilRpm(end) - silRpm(end);

fprintf('\n---------------- SIL/HIL EQUIVALENCE SUMMARY -------------------\n');
fprintf('  Speed RMSE:                  %10.3f RPM (Threshold: < 10 RPM)\n', metrics.speed_rmse_rpm);
fprintf('  Maximum Absolute Difference: %10.3f RPM (Threshold: < 25 RPM)\n', metrics.speed_max_abs_rpm);
fprintf('  Peak Speed Difference:       %10.3f RPM\n', metrics.peak_speed_difference_rpm);
fprintf('  Final Speed Difference:      %10.3f RPM (Threshold: < 10 RPM)\n', metrics.final_speed_difference_rpm);
fprintf('----------------------------------------------------------------\n');

% Assertions
assert(metrics.speed_rmse_rpm < 10, 'SIL/HIL speed RMSE exceeds 10 RPM.');
assert(metrics.speed_max_abs_rpm < 25, 'SIL/HIL maximum speed difference exceeds 25 RPM.');
assert(abs(metrics.final_speed_difference_rpm) < 10, 'SIL/HIL final speed difference exceeds 10 RPM.');
fprintf('>>> SIL/HIL equivalence criteria fully satisfied! <<<\n\n');

% 5. Detailed Comparison Figure
fig = figure('Name', 'Stugverter SIL vs HIL Equivalence Comparison', ...
             'NumberTitle', 'off', 'Color', 'w');
set(fig, 'Position', [100, 100, 950, 750], 'Visible', 'on');

% Subplot 1: Speed Tracking Comparison
subplot(3, 1, 1);
plot(sampleGrid, refRpm, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Reference (RPM)');
hold on;
plot(sampleGrid, silRpm, 'b-', 'LineWidth', 1.3, 'DisplayName', 'SIL Model (Simulink)');
plot(sampleGrid, hilRpm, 'r-', 'LineWidth', 1.3, 'DisplayName', 'HIL Target (AURIX TC387)');
grid on;
title('Rotor Mechanical Speed: SIL vs. AURIX TC387 HIL Overlay');
xlabel('Time [s]');
ylabel('Speed [RPM]');
legend('Location', 'best');

% Subplot 2: Difference (HIL - SIL)
subplot(3, 1, 2);
plot(sampleGrid, speed_diff, 'm-', 'LineWidth', 1.2, 'DisplayName', 'HIL - SIL Speed Error');
hold on;
yline(0, 'k:');
yline(10, 'r--', 'DisplayName', '+10 RPM Limit');
yline(-10, 'r--', 'DisplayName', '-10 RPM Limit');
grid on;
title(sprintf('Speed Discrepancy (HIL - SIL): RMSE = %.2f RPM, Max = %.2f RPM', ...
    metrics.speed_rmse_rpm, metrics.speed_max_abs_rpm));
xlabel('Time [s]');
ylabel('Difference [RPM]');
legend('Location', 'best');

% Subplot 3: PWM Duty Comparison
subplot(3, 1, 3);
hasDutySil = isfield(silOut, 'scope_duty') || isprop(silOut, 'scope_duty');
hasDutyHil = isfield(hilOut, 'scope_duty') || isprop(hilOut, 'scope_duty');
if hasDutySil && hasDutyHil
    dSil = silOut.scope_duty{1}.Values;
    dHil = hilOut.scope_duty{1}.Values;
    plot(dSil.Time, dSil.Data(:, 1), 'b-', 'LineWidth', 1.0, 'DisplayName', 'Duty U (SIL)');
    hold on;
    plot(dHil.Time, dHil.Data(:, 1), 'r--', 'LineWidth', 1.0, 'DisplayName', 'Duty U (HIL)');
    grid on;
    title('Phase U Inverter Duty Cycle: SIL vs. HIL');
    xlabel('Time [s]');
    ylabel('Duty [0-1]');
    legend('Location', 'best');
else
    title('Duty telemetry comparison');
end

drawnow;
fprintf('[+] Comparison figure opened directly for investigation.\n');
