% test_optimized_controller.m
function test_optimized_controller()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_speedcontroller');
    load_system('foc_plant');
    load_system('foc_controller');
    
    disp('=== 1. Setting up Filtered Actual Speed to MTPA block ===');
    % Remove existing connection to MTPA inport 2 (wm)
    try
        delete_line('foc_system', 'RPM_to_RadPerSec/1', 'MTPA Control Reference/2');
        delete_block('foc_system/RPM_to_RadPerSec');
    catch
    end
    
    % Connect actual speed measurement (in rad/s) from plant through a 1st-order low-pass filter
    % Plant measurement bus element 3 is 'speed' in rad/s
    % Let's add a Discrete Transfer Fcn or Transfer Fcn filter 1/(0.005s + 1)
    try
        delete_block('foc_system/SpeedFilter_MTPA');
    catch
    end
    try
        add_block('simulink/Continuous/Transfer Fcn', 'foc_system/SpeedFilter_MTPA', ...
            'Numerator', '[1]', 'Denominator', '[0.005 1]', 'Position', [1230, 480, 1290, 510]);
        % Connect from Bus Selector1 (which extracts <speed>) to SpeedFilter_MTPA
        add_line('foc_system', 'Bus Selector1/1', 'SpeedFilter_MTPA/1', 'autorouting', 'on');
        add_line('foc_system', 'SpeedFilter_MTPA/1', 'MTPA Control Reference/2', 'autorouting', 'on');
    catch ME
        fprintf('Note on filter connection: %s\n', ME.message);
    end
    
    disp('=== 2. Optimizing foc_speedcontroller ===');
    % We will test 2-DOF / Setpoint filter vs tuned PI
    % Let's tune the speed controller PI with critically-damped gains:
    % P = 0.008, I = 0.08 with clamping anti-windup
    set_param('foc_speedcontroller/PI Controller', 'Controller', 'PI');
    set_param('foc_speedcontroller/PI Controller', 'P', '0.006');
    set_param('foc_speedcontroller/PI Controller', 'I', '0.06');
    set_param('foc_speedcontroller/PI Controller', 'UpperSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'UpperIntegratorSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerIntegratorSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'AntiWindupMode', 'clamping');
    
    % In foc_speedcontroller, let's also add a Setpoint Pre-Filter (First-Order Filter)
    % to eliminate the reference zero s = -I/P = -10 rad/s
    % Pre-filter transfer function: F(s) = 1 / ((P/I)*s + 1) = 1 / (0.1*s + 1)
    % Or a Rate Limiter with 150,000 rpm/s
    % Let's test first with pure PI and pre-filter
    
    save_system('foc_speedcontroller');
    save_system('foc_system');
    
    % Let's run a test simulation with the multi-step profile
    t_profile = [0, 0.05, 0.05, 0.15, 0.15, 0.28, 0.28, 0.38];
    spd_profile = [0, 0, 8000, 8000, 18000, 18000, 6000, 6000];
    sp_ts = timeseries(spd_profile, t_profile);
    assignin('base', 'sp_ts', sp_ts);
    
    set_param('foc_system/SpeedProfile', 'VariableName', 'sp_ts');
    set_param('foc_system', 'StopTime', '0.38');
    
    fprintf('Running simulation test...\n');
    simOut = sim('foc_system');
    logs = simOut.get('logsout');
    
    spd_ref = logs.get('Speed_Ref').Values;
    spd_meas = logs.get('Speed_Meas').Values;
    spdc_out = logs.get('SpeedCtrl_Out').Values;
    id_ref = logs.get('id_ref').Values;
    iq_ref = logs.get('iq_ref').Values;
    
    f = figure('Visible', 'off', 'Position', [100 100 1000 850]);
    
    subplot(3,1,1);
    plot(spd_ref.Time*1000, squeeze(spd_ref.Data), 'r--', 'LineWidth', 2); hold on;
    plot(spd_meas.Time*1000, squeeze(spd_meas.Data), 'b-', 'LineWidth', 1.8);
    yline(13650, 'k:', 'Base Speed n_{base} = 13,650 rpm', 'LineWidth', 1.5);
    grid on;
    ylabel('Speed [rpm]', 'FontSize', 11, 'FontWeight', 'bold');
    title('PMSM FOC Drive: Optimized Speed Tracking Response', 'FontSize', 13, 'FontWeight', 'bold');
    legend('Reference Speed', 'Actual Rotor Speed', 'Base Speed Threshold (13,650 rpm)', 'Location', 'northwest');
    ylim([-500, 21000]);
    
    subplot(3,1,2);
    plot(id_ref.Time*1000, squeeze(id_ref.Data), 'b-', 'LineWidth', 2); hold on;
    plot(iq_ref.Time*1000, squeeze(iq_ref.Data), 'g-', 'LineWidth', 2);
    yline(0, 'k-', 'Alpha', 0.3);
    grid on;
    ylabel('Currents [A]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Stator Currents in Rotor Frame: i_d (Field Weakening) & i_q (Torque)', 'FontSize', 12, 'FontWeight', 'bold');
    legend('i_d^{ref} (Field Weakening)', 'i_q^{ref} (Torque producing current)', 'Location', 'best');
    
    subplot(3,1,3);
    plot(spdc_out.Time*1000, squeeze(spdc_out.Data), 'm-', 'LineWidth', 1.8);
    grid on;
    ylabel('Torque [Nm]', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Time [ms]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Speed Controller Output (T_{ref})', 'FontSize', 12, 'FontWeight', 'bold');
    legend('T_{ref} (Saturated at T_{peak} = 29.1 Nm)', 'Location', 'best');
    
    saveas(f, 'optimized_test_1.png');
    close(f);
    
    fprintf('Saved plot to optimized_test_1.png\n');
end
