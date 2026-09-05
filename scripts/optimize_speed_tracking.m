% optimize_speed_tracking.m
function optimize_speed_tracking()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_speedcontroller');
    load_system('foc_plant');
    load_system('foc_controller');
    
    disp('=== Optimizing Speed Tracking in foc_speedcontroller and foc_system ===');
    
    % 1. MTPA Block Speed Input Connection:
    % Disconnect inport 2 of MTPA Control Reference
    ph_mtpa = get_param('foc_system/MTPA Control Reference', 'PortHandles');
    line_mtpa_in2 = get_param(ph_mtpa.Inport(2), 'Line');
    if line_mtpa_in2 ~= -1
        delete_line(line_mtpa_in2);
    end
    try
        delete_block('foc_system/RPM_to_RadPerSec');
    catch
    end
    try
        delete_block('foc_system/SpeedFilter_MTPA');
    catch
    end
    add_block('simulink/Continuous/Transfer Fcn', 'foc_system/SpeedFilter_MTPA', ...
        'Numerator', '[1]', 'Denominator', '[0.005 1]', 'Position', [1230, 480, 1290, 510]);
    add_line('foc_system', 'Bus Selector1/1', 'SpeedFilter_MTPA/1', 'autorouting', 'on');
    add_line('foc_system', 'SpeedFilter_MTPA/1', 'MTPA Control Reference/2', 'autorouting', 'on');

    % 2. Inside foc_speedcontroller:
    ph_sub = get_param('foc_speedcontroller/Subtract', 'PortHandles');
    line_sub_in1 = get_param(ph_sub.Inport(1), 'Line');
    if line_sub_in1 ~= -1
        delete_line(line_sub_in1);
    end
    try
        delete_block('foc_speedcontroller/Setpoint_Filter');
    catch
    end
    add_block('simulink/Continuous/Transfer Fcn', 'foc_speedcontroller/Setpoint_Filter', ...
        'Numerator', '[1]', 'Denominator', '[0.012 1]', 'Position', [760, 360, 810, 390]);
    add_line('foc_speedcontroller', 'set_speed/1', 'Setpoint_Filter/1', 'autorouting', 'on');
    add_line('foc_speedcontroller', 'Setpoint_Filter/1', 'Subtract/1', 'autorouting', 'on');

    % 3. Speed PI Controller Tuning:
    % P = 0.012 Nm/rpm, I = 0.15 Nm/(rpm*s)
    % Upper & Lower limits = +/- 29.1 Nm (pmsm.T_peak)
    set_param('foc_speedcontroller/PI Controller', 'Controller', 'PI');
    set_param('foc_speedcontroller/PI Controller', 'P', '0.012');
    set_param('foc_speedcontroller/PI Controller', 'I', '0.15');
    set_param('foc_speedcontroller/PI Controller', 'UpperSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'UpperIntegratorSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerIntegratorSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'AntiWindupMode', 'clamping');

    save_system('foc_speedcontroller');
    save_system('foc_system');

    % 4. Enable Signal Logging on root ports
    ph_sp = get_param('foc_system/SpeedProfile', 'PortHandles');
    set_param(ph_sp.Outport(1), 'DataLogging', 'on');
    set_param(ph_sp.Outport(1), 'DataLoggingNameMode', 'Custom');
    set_param(ph_sp.Outport(1), 'DataLoggingName', 'Speed_Ref');
    
    ph_gain = get_param('foc_system/Gain', 'PortHandles');
    set_param(ph_gain.Outport(1), 'DataLogging', 'on');
    set_param(ph_gain.Outport(1), 'DataLoggingNameMode', 'Custom');
    set_param(ph_gain.Outport(1), 'DataLoggingName', 'Speed_Meas');

    ph_model = get_param('foc_system/Model', 'PortHandles');
    set_param(ph_model.Outport(1), 'DataLogging', 'on');
    set_param(ph_model.Outport(1), 'DataLoggingNameMode', 'Custom');
    set_param(ph_model.Outport(1), 'DataLoggingName', 'SpeedCtrl_Out');

    ph_mtpa = get_param('foc_system/MTPA Control Reference', 'PortHandles');
    set_param(ph_mtpa.Outport(1), 'DataLogging', 'on');
    set_param(ph_mtpa.Outport(1), 'DataLoggingNameMode', 'Custom');
    set_param(ph_mtpa.Outport(1), 'DataLoggingName', 'id_ref');
    
    set_param(ph_mtpa.Outport(2), 'DataLogging', 'on');
    set_param(ph_mtpa.Outport(2), 'DataLoggingNameMode', 'Custom');
    set_param(ph_mtpa.Outport(2), 'DataLoggingName', 'iq_ref');
    
    set_param('foc_system', 'SignalLogging', 'on');
    set_param('foc_system', 'SignalLoggingName', 'logsout');

    % Test profile: 0 -> 8000 -> 18000 -> 6000 rpm
    t_profile = [0, 0.05, 0.05, 0.15, 0.15, 0.28, 0.28, 0.38];
    spd_profile = [0, 0, 8000, 8000, 18000, 18000, 6000, 6000];
    sp_ts = timeseries(spd_profile, t_profile);
    assignin('base', 'sp_ts', sp_ts);
    
    set_param('foc_system/SpeedProfile', 'VariableName', 'sp_ts');
    set_param('foc_system', 'StopTime', '0.38');
    
    fprintf('Running optimized simulation...\n');
    simOut = sim('foc_system');
    logs = simOut.get('logsout');
    
    spd_ref = logs.get('Speed_Ref').Values;
    spd_meas = logs.get('Speed_Meas').Values;
    spdc_out = logs.get('SpeedCtrl_Out').Values;
    id_ref = logs.get('id_ref').Values;
    iq_ref = logs.get('iq_ref').Values;
    
    f = figure('Visible', 'off', 'Position', [100 100 1000 850]);
    
    % Subplot 1: Speed Tracking
    subplot(3,1,1);
    plot(spd_ref.Time*1000, squeeze(spd_ref.Data), 'r--', 'LineWidth', 2); hold on;
    plot(spd_meas.Time*1000, squeeze(spd_meas.Data), 'b-', 'LineWidth', 2);
    yline(13650, 'k:', 'Base Speed n_{base} = 13,650 rpm', 'LineWidth', 1.5);
    grid on;
    ylabel('Speed [rpm]', 'FontSize', 11, 'FontWeight', 'bold');
    title('PMSM FOC Drive: Highly Optimized Speed Tracking (MTPA + Field Weakening)', 'FontSize', 13, 'FontWeight', 'bold');
    legend('Reference Speed', 'Actual Rotor Speed', 'Base Speed Threshold (13,650 rpm)', 'Location', 'northwest');
    ylim([-500, 21000]);
    
    % Subplot 2: d-axis & q-axis Current Reference
    subplot(3,1,2);
    plot(id_ref.Time*1000, squeeze(id_ref.Data), 'b-', 'LineWidth', 2); hold on;
    plot(iq_ref.Time*1000, squeeze(iq_ref.Data), 'g-', 'LineWidth', 2);
    yline(0, 'k-', 'Alpha', 0.3);
    grid on;
    ylabel('Currents [A]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Stator Currents in Rotor Frame: i_d (Field Weakening) & i_q (Torque)', 'FontSize', 12, 'FontWeight', 'bold');
    legend('i_d^{ref} (Field Weakening)', 'i_q^{ref} (Torque producing current)', 'Location', 'best');
    
    % Subplot 3: Speed Controller Torque Demand
    subplot(3,1,3);
    plot(spdc_out.Time*1000, squeeze(spdc_out.Data), 'm-', 'LineWidth', 1.8);
    grid on;
    ylabel('Torque [Nm]', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Time [ms]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Speed Controller Output (T_{ref})', 'FontSize', 12, 'FontWeight', 'bold');
    legend('T_{ref} (Saturated at T_{peak} = 29.1 Nm)', 'Location', 'best');
    
    saveas(f, 'speed_tracking_optimized.png');
    close(f);
    
    fprintf('Saved optimized plot to speed_tracking_optimized.png\n');
end
