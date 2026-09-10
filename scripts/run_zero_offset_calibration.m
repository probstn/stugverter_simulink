function results = run_zero_offset_calibration()
%RUN_ZERO_OFFSET_CALIBRATION Safely calibrate current and resolver zero only.
%   The target is held in mode OFF with the operator enable released. The
%   script requests CURRENT_ZERO and RESOLVER_ZERO separately, verifies the
%   supervisor transitions and final safe state, then saves a result record.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
modelsDir = fullfile(simulinkDir, 'models');
addpath(fullfile(simulinkDir, 'scripts'), modelsDir);
evalin('base', sprintf('run(''%s'')', strrep(fullfile(simulinkDir, 'scripts', 'init.m'), '''', '''''')));

modelName = 'stugverter_monitor';
modelFile = fullfile(modelsDir, [modelName '.slx']);
backend = [modelName '/Communications Backend'];
daqPath = [backend '/XCP UDP Data Acquisition'];

wait_for_xcp('192.168.0.10', 5555, '192.168.0.100', 15);
load_system(modelFile);

% Add raw ADC evidence after the stable dashboard channel set. Appending keeps
% all existing output-port bindings unchanged.
selected = get_param(daqPath, 'SelectedMeasurements');
rawNames = {'g_adc_raw_curr_u','g_adc_raw_curr_v','g_adc_raw_curr_w', ...
    'g_adc_raw_res_sin','g_adc_raw_res_cos','g_foc_isr_counter', ...
    'g_calibration_settle_count'};
for rawName = rawNames
    if ~contains([';' selected ';'], [';' rawName{1} ';'])
        selected = [selected ';' rawName{1}]; %#ok<AGROW>
    end
end
set_param(daqPath, 'SelectedMeasurements', selected);

set_param([backend '/Enable Request Value'], 'Value', '0');
set_param([backend '/Mode Request'], 'Value', '0');
set_param([backend '/Calibration Request'], 'Value', '0');
set_param([backend '/Execute Calibration'], 'Value', '0');
set_param([backend '/Fault Reset'], 'Value', '0');
set_param([backend '/Torque Reference'], 'Value', '0');
set_param([backend '/Open Loop Hz'], 'Value', '0');
set_param([backend '/Open Loop Modulation'], 'Value', '0');
set_param([backend '/Calibration Modulation'], 'Value', '0.005');
set_param(modelName, 'StopTime', 'inf', 'EnablePacing', 'on', 'PacingRate', '1');

cleanup = onCleanup(@() safeStopModel(modelName, backend));
set_param(modelName, 'SimulationCommand', 'start');
waitForStatus('running', 10);
pause(0.5);

names = strsplit(get_param(daqPath, 'SelectedMeasurements'), ';');
idx = @(name) find(strcmp(names, name), 1);

pre = snapshot();
disp(pre);
assertDeenergized(pre, 'initial connection');
afterReset = pre;
if pre.fault_flags ~= 0
    expectedStartupLatch = uint32(hex2dec('1FF'));
    unexpected = bitand(uint32(pre.fault_flags), bitcmp(expectedStartupLatch, 'uint32'));
    if unexpected ~= 0 || max(abs([pre.curr_u pre.curr_v pre.curr_w])) >= 1 || abs(pre.speed_rad_s) >= 100
        error('Refusing fault reset: fault pattern or live measurements are not consistent with the known safe startup latch.');
    end
    set_param([backend '/Fault Reset'], 'Value', '1');
    pause(0.2);
    set_param([backend '/Fault Reset'], 'Value', '0');
    pause(0.25);
    afterReset = snapshot();
    disp(afterReset);
    assertSafeIdle(afterReset, 'post-reset state');
    fprintf('[OK] Cleared stale startup current-protection latch without enabling PWM.\n');
end
fprintf('[OK] Target connected safely: mode OFF, PWM disabled, gates disabled.\n');

% Request 1: current-sensor zero. PWM/gates must remain disabled throughout.
currentTrace = runRequest(1, false, 4.0);
set_param([backend '/Calibration Request'], 'Value', '0');
pause(0.25);
currentResidual = sampleSignals(0.75);
fprintf('[OK] Current-zero calibration completed with gates disabled.\n');

% Request 2: resolver mechanical zero. This uses only the configured tiny
% alignment modulation; no torque, speed, or open-loop control mode is entered.
angleTrace = runRequest(2, true, 8.0);
set_param([backend '/Calibration Request'], 'Value', '0');
pause(0.3);
final = snapshot();
postAngleLatchedFlags = final.fault_flags;
if final.fault_flags ~= 0 && bitand(uint32(final.fault_flags), uint32(256)) == 0
    assertDeenergized(final, 'post-angle reset');
    set_param([backend '/Fault Reset'], 'Value', '1');
    pause(0.2);
    set_param([backend '/Fault Reset'], 'Value', '0');
    pause(0.25);
    final = snapshot();
end
disp(final);
assertSafeIdle(final, 'final state');
angleCompleted = any([angleTrace.calibration_complete] == 1) || ...
    any([angleTrace.calibration_sample_count] >= 10000);
if ~angleCompleted
    error('Resolver calibration did not reach its 10000-sample completion condition.');
end
gateOn = [angleTrace.gates_enabled] == 1 & [angleTrace.pwm_enable] == 1;
if ~any(gateOn)
    error('Resolver calibration completed without observed PWM permission and gate enable.');
end
gateIsrTicks = [angleTrace(gateOn).isr_counter];
gateOnDuration = (gateIsrTicks(end) - gateIsrTicks(1)) / 20000;
if ~any([angleTrace.calibration_settle_count] >= 20000)
    error('Resolver alignment did not complete the required 20000 target settle ticks.');
end
if gateOnDuration < 1.20
    error('Observed resolver gate-on window was only %.3f target seconds.', gateOnDuration);
end
fprintf('[OK] Resolver-zero calibration completed and returned to safe idle.\n');

results = struct;
results.timestamp = datetime('now', 'TimeZone', 'local');
results.target = '192.168.0.10:5555';
results.supply_note = 'User-confirmed 20 V / 1 A current limit';
results.calibration_modulation = str2double(get_param([backend '/Calibration Modulation'], 'Value'));
results.initial = pre;
results.after_safe_fault_reset = afterReset;
results.current_trace = currentTrace;
results.current_residual_mean_A = mean(currentResidual.currents, 1);
results.current_residual_rms_A = sqrt(mean(currentResidual.currents.^2, 1));
results.current_residual_peak_A = max(abs(currentResidual.currents), [], 1);
results.angle_trace = angleTrace;
results.observed_angle_gate_on_lower_bound_s = gateOnDuration;
results.alignment_current_peak_A = max(abs([[angleTrace.curr_u].', ...
    [angleTrace.curr_v].', [angleTrace.curr_w].']), [], 1);
results.post_angle_latched_flags = postAngleLatchedFlags;
results.final = final;
results.passed = true;

resultFile = fullfile(simulinkDir, 'zero_offset_calibration_results.mat');
save(resultFile, 'results');
fprintf('[OK] Saved calibration evidence: %s\n', resultFile);
fprintf('     Current residual mean [A]:  U=%+.5f  V=%+.5f  W=%+.5f\n', results.current_residual_mean_A);
fprintf('     Current residual RMS  [A]:  U= %.5f  V= %.5f  W= %.5f\n', results.current_residual_rms_A);
fprintf('     Learned current offsets:   U=%.3f  V=%.3f  W=%.3f counts\n', ...
    final.current_offset_u, final.current_offset_v, final.current_offset_w);
fprintf('     Resolver offset [rad]: %.6f; zeroed angle [rad]: %.6f\n', ...
    final.resolver_offset_runtime, final.theta_mech);
fprintf('     Resolver samples: %u\n', uint32(final.calibration_sample_count));
fprintf('     Observed alignment gate-on lower bound: %.3f s\n', gateOnDuration);
fprintf('     Alignment current peak [A]: U=%.3f  V=%.3f  W=%.3f\n', ...
    results.alignment_current_peak_A);
delete(cleanup);

    function trace = runRequest(request, allowGates, timeout)
        set_param([backend '/Calibration Request'], 'Value', '0');
        set_param([backend '/Execute Calibration'], 'Value', '0');
        pause(0.2);
        set_param([backend '/Calibration Request'], 'Value', num2str(request));
        set_param([backend '/Execute Calibration'], 'Value', '1');
        started = false;
        done = false;
        trace = repmat(snapshot(), 0, 1);
        startedAt = tic;
        while toc(startedAt) < timeout
            s = snapshot();
            trace(end+1, 1) = s; %#ok<AGROW>
            targetTripped = bitand(uint32(s.fault_flags), uint32(256)) ~= 0 || s.supervisor_state == 2;
            if targetTripped
                error(['Calibration request %d tripped the target: flags=0x%08X, ' ...
                    'state=%g, speed=%.3f rad/s, currents=[%.3f %.3f %.3f] A.'], ...
                    request, uint32(s.fault_flags), s.supervisor_state, s.speed_rad_s, ...
                    s.curr_u, s.curr_v, s.curr_w);
            end
            if s.active_mode ~= 0
                error('Calibration request %d entered active control mode %g.', request, s.active_mode);
            end
            if ~allowGates && (s.pwm_enable ~= 0 || s.gates_enabled ~= 0)
                error('Current-zero calibration unexpectedly enabled PWM or gate drivers.');
            end
            started = started || (s.supervisor_state == 1);
            if started
                set_param([backend '/Execute Calibration'], 'Value', '0');
            end
            done = started && (s.supervisor_state ~= 1);
            if done
                break;
            end
            pause(0.02);
        end
        if ~started || ~done
            error('Calibration request %d did not complete within %.1f seconds.', request, timeout);
        end
        set_param([backend '/Calibration Request'], 'Value', '0');
        set_param([backend '/Execute Calibration'], 'Value', '0');
    end

    function samples = sampleSignals(duration)
        values = zeros(0, 3);
        startedAt = tic;
        while toc(startedAt) < duration
            s = snapshot();
            if s.fault_flags ~= 0 || s.gates_enabled ~= 0 || s.pwm_enable ~= 0
                error('Unsafe state while checking post-calibration current residuals.');
            end
            values(end+1, :) = [s.curr_u s.curr_v s.curr_w]; %#ok<AGROW>
            pause(0.02);
        end
        samples = struct('currents', values);
    end

    function s = snapshot()
        rto = get_param(daqPath, 'RuntimeObject');
        read = @(name) double(rto.OutputPort(idx(name)).Data);
        s = struct( ...
            'time_s', tocFromModel(), ...
            'isr_counter', read('g_foc_isr_counter'), ...
            'curr_u', read('g_meas_curr_u'), ...
            'curr_v', read('g_meas_curr_v'), ...
            'curr_w', read('g_meas_curr_w'), ...
            'raw_curr_u', read('g_adc_raw_curr_u'), ...
            'raw_curr_v', read('g_adc_raw_curr_v'), ...
            'raw_curr_w', read('g_adc_raw_curr_w'), ...
            'raw_resolver_sin', read('g_adc_raw_res_sin'), ...
            'raw_resolver_cos', read('g_adc_raw_res_cos'), ...
            'current_offset_u', read('g_current_offset_u'), ...
            'current_offset_v', read('g_current_offset_v'), ...
            'current_offset_w', read('g_current_offset_w'), ...
            'resolver_offset_runtime', read('g_resolver_offset_runtime'), ...
            'speed_rad_s', read('g_meas_speed'), ...
            'theta_mech', read('g_meas_theta_mech'), ...
            'active_mode', read('g_supervisor_active_mode'), ...
            'pwm_enable', read('g_supervisor_pwm_enable'), ...
            'gates_enabled', read('g_gate_drivers_enabled'), ...
            'calibration_sample_count', read('g_calibration_sample_count'), ...
            'calibration_settle_count', read('g_calibration_settle_count'), ...
            'calibration_complete', read('g_calibration_complete'), ...
            'configured_resolver_offset', read('resolver_angle_offset'), ...
            'has_stored_resolver_offset', read('has_stored_resolver_offset'), ...
            'supervisor_state', read('g_supervisor_state'), ...
            'xcp_timeout_count', read('g_xcp_command_timeout_count'), ...
            'startup_current_cal_done', read('g_startup_current_cal_done'), ...
            'fault_flags', read('g_fault_flags'));
    end

    function t = tocFromModel()
        t = double(get_param(modelName, 'SimulationTime'));
    end

    function assertSafeIdle(s, context)
        assertDeenergized(s, context);
        if s.fault_flags ~= 0
            error('Unsafe %s: mode=%g pwm=%g gates=%g faults=0x%08X.', ...
                context, s.active_mode, s.pwm_enable, s.gates_enabled, uint32(s.fault_flags));
        end
    end

    function assertDeenergized(s, context)
        if s.active_mode ~= 0 || s.pwm_enable ~= 0 || s.gates_enabled ~= 0
            error('Unsafe %s: mode=%g pwm=%g gates=%g faults=0x%08X.', ...
                context, s.active_mode, s.pwm_enable, s.gates_enabled, uint32(s.fault_flags));
        end
    end

    function waitForStatus(expected, timeout)
        startedAt = tic;
        while toc(startedAt) < timeout
            if strcmp(get_param(modelName, 'SimulationStatus'), expected)
                return;
            end
            pause(0.05);
        end
        error('Monitor did not reach simulation status %s.', expected);
    end

end

function safeStopModel(modelName, backend)
try
    set_param([backend '/Calibration Request'], 'Value', '0');
    set_param([backend '/Execute Calibration'], 'Value', '0');
catch
end
try
    set_param([backend '/Enable Request Value'], 'Value', '0');
catch
end
try
    set_param([backend '/Mode Request'], 'Value', '0');
catch
end
try
    pause(0.25);
catch
end
try
    if ~strcmp(get_param(modelName, 'SimulationStatus'), 'stopped')
        set_param(modelName, 'SimulationCommand', 'stop');
    end
catch
end
try
    close_system(modelName, 0);
catch
end
end
