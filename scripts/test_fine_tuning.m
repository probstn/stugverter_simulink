% test_fine_tuning.m
function test_fine_tuning()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_speedcontroller');
    
    % Let's tune speed PI controller:
    % P = 0.005, I = 0.05, D = 0.0001
    set_param('foc_speedcontroller/PI Controller', 'Controller', 'PID');
    set_param('foc_speedcontroller/PI Controller', 'P', '0.008');
    set_param('foc_speedcontroller/PI Controller', 'I', '0.08');
    set_param('foc_speedcontroller/PI Controller', 'D', '0.0001');
    set_param('foc_speedcontroller/PI Controller', 'N', '100');
    set_param('foc_speedcontroller/PI Controller', 'UpperSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'UpperIntegratorSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerIntegratorSaturationLimit', '-pmsm.T_peak');
    
    save_system('foc_speedcontroller');
    
    % Multi-step reference: 0 -> 8000 -> 18000 -> 6000 rpm
    t_profile = [0, 0.05, 0.05, 0.15, 0.15, 0.28, 0.28, 0.38];
    spd_profile = [0, 0, 8000, 8000, 18000, 18000, 6000, 6000];
    sp_ts = timeseries(spd_profile, t_profile);
    assignin('base', 'sp_ts', sp_ts);
    
    set_param('foc_system/SpeedProfile', 'VariableName', 'sp_ts');
    set_param('foc_system', 'StopTime', '0.38');
    
    fprintf('Running simulation with fine-tuned PID speed controller...\n');
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
    plot(spd_meas.Time*1000, squeeze(spd_meas.Data), 'b-', 'LineWidth', 1.8);
    yline(13650, 'k:', 'Base Speed n_{base} = 13,650 rpm', 'LineWidth', 1.5);
    grid on;
    ylabel('Speed [rpm]', 'FontSize', 11, 'FontWeight', 'bold');
    title('PMSM FOC Drive: MTPA & Field Weakening Response (Fine-Tuned Controller)', 'FontSize', 13, 'FontWeight', 'bold');
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
    
    saveas(f, 'fine_tuned_multi_step_validation.png');
    close(f);
    
    fprintf('Saved fine-tuned plot to fine_tuned_multi_step_validation.png\n');
end
