% test_speed_optimization_suite.m
function test_speed_optimization_suite()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_speedcontroller');
    load_system('foc_plant');
    load_system('foc_controller');
    
    disp('=== Designing Optimal Speed Controller ===');
    
    % Motor parameters:
    % J = 0.33e-3 kg*m^2
    % T_peak = 29.1 Nm
    % Gain from Torque (Nm) to Speed derivative (rpm/s):
    % K_plant = (30/pi) / J = 28937.2 rpm/(Nm*s)
    
    % Target: Critically damped closed-loop (zeta = 1.0), omega_n = 120 rad/s (f_bw ~ 19 Hz)
    omega_n = 120; % rad/s
    zeta = 1.0;    % critically damped
    K_plant = (30/pi) / pmsm.J;
    
    Kp_rpm = (2 * zeta * omega_n) / K_plant;  % ~0.0083 Nm/rpm
    Ki_rpm = (omega_n^2) / K_plant;            % ~0.4976 Nm/(rpm*s)
    tau_filter = Kp_rpm / Ki_rpm;              % ~0.0167 s (16.7 ms)
    
    fprintf('Optimal PI Gains:\n');
    fprintf('  Kp = %.5f Nm/rpm\n', Kp_rpm);
    fprintf('  Ki = %.5f Nm/(rpm*s)\n', Ki_rpm);
    fprintf('  Zero Cancellation Filter Time Constant = %.4f s (%.1f ms)\n', tau_filter, tau_filter*1000);
    
    % Set PI Controller in foc_speedcontroller
    set_param('foc_speedcontroller/PI Controller', 'Controller', 'PI');
    set_param('foc_speedcontroller/PI Controller', 'P', num2str(Kp_rpm, '%.6f'));
    set_param('foc_speedcontroller/PI Controller', 'I', num2str(Ki_rpm, '%.6f'));
    set_param('foc_speedcontroller/PI Controller', 'UpperSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'UpperIntegratorSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerIntegratorSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'AntiWindupMode', 'clamping');
    
    save_system('foc_speedcontroller');
    save_system('foc_system');
    
    % Set up speed profile (same step sequence as in user screenshot)
    t_profile = [0, 0.05, 0.05, 0.15, 0.15, 0.28, 0.28, 0.38];
    spd_profile = [0, 0, 8000, 8000, 18000, 18000, 6000, 6000];
    sp_ts = timeseries(spd_profile, t_profile);
    assignin('base', 'sp_ts', sp_ts);
    
    set_param('foc_system/SpeedProfile', 'VariableName', 'sp_ts');
    set_param('foc_system', 'StopTime', '0.38');
    
    % Setup Signal Logging on foc_system
    set_param('foc_system', 'SignalLogging', 'on');
    set_param('foc_system', 'SignalLoggingName', 'logsout');
    
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
    
    save_system('foc_system');
    
    fprintf('Running simulation with optimal PI gains...\n');
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
    title('PMSM FOC Drive: Optimized Speed Tracking Response', 'FontSize', 13, 'FontWeight', 'bold');
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
    
    saveas(f, 'speed_optimization_test.png');
    close(f);
    
    fprintf('Saved plot to speed_optimization_test.png\n');
end
