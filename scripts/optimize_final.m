% optimize_final.m
function optimize_final()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_controller');
    load_system('foc_speedcontroller');
    load_system('foc_plant');
    
    disp('=== 1. Current Controller Configuration ===');
    % Keep robust current controller gains
    set_param('foc_controller/Id Controller', 'P', '2.312');
    set_param('foc_controller/Id Controller', 'I', '15.0');
    set_param('foc_controller/Id Controller', 'AntiWindupMode', 'clamping');
    set_param('foc_controller/Id Controller', 'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)');
    set_param('foc_controller/Id Controller', 'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)');
    
    set_param('foc_controller/Iq Controller', 'P', '2.312');
    set_param('foc_controller/Iq Controller', 'I', '15.0');
    set_param('foc_controller/Iq Controller', 'AntiWindupMode', 'clamping');
    set_param('foc_controller/Iq Controller', 'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)');
    set_param('foc_controller/Iq Controller', 'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)');
    save_system('foc_controller');
    
    disp('=== 2. Speed Controller Optimization ===');
    % Optimal speed controller tuning for SPMSM with J = 0.33e-3:
    % P = 0.005 Nm/rpm
    % I = 0.035 Nm/(rpm*s)
    % D = 0.00008 Nm/(rpm/s) with filter N = 250 rad/s
    set_param('foc_speedcontroller/PI Controller', 'Controller', 'PID');
    set_param('foc_speedcontroller/PI Controller', 'P', '0.005');
    set_param('foc_speedcontroller/PI Controller', 'I', '0.035');
    set_param('foc_speedcontroller/PI Controller', 'D', '0.00008');
    set_param('foc_speedcontroller/PI Controller', 'N', '250');
    set_param('foc_speedcontroller/PI Controller', 'UpperSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'UpperIntegratorSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerIntegratorSaturationLimit', '-pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'AntiWindupMode', 'clamping');
    save_system('foc_speedcontroller');
    
    disp('=== 3. Top-Level Slew Rate & MTPA Setup ===');
    % Rate limiter on speed reference for smooth, physically realizable acceleration:
    % Slew rate = 300,000 rpm/s (reaches 18,000 rpm in 60 ms!)
    set_param('foc_system/Speed_Rate_Limiter', 'RisingSlewLimit', '300000', 'FallingSlewLimit', '-300000');
    save_system('foc_system');
    
    % Multi-step reference: 0 -> 8000 -> 18000 -> 6000 rpm
    t_profile = [0, 0.05, 0.05, 0.15, 0.15, 0.28, 0.28, 0.38];
    spd_profile = [0, 0, 8000, 8000, 18000, 18000, 6000, 6000];
    sp_ts = timeseries(spd_profile, t_profile);
    assignin('base', 'sp_ts', sp_ts);
    
    set_param('foc_system/SpeedProfile', 'VariableName', 'sp_ts');
    set_param('foc_system', 'StopTime', '0.38');
    
    fprintf('Running simulation...\n');
    simOut = sim('foc_system');
    logs = simOut.get('logsout');
    
    spd_ref = getSignalValues(logs, 'Speed_Ref');
    spd_meas = getSignalValues(logs, 'Speed_Meas');
    spdc_out = getSignalValues(logs, 'SpeedCtrl_Out');
    id_ref = getSignalValues(logs, 'id_ref');
    iq_ref = getSignalValues(logs, 'iq_ref');
    
    f = figure('Visible', 'off', 'Position', [100 100 1000 850]);
    
    % Subplot 1: Speed Tracking
    subplot(3,1,1);
    plot(spd_ref.Time*1000, squeeze(spd_ref.Data), 'r--', 'LineWidth', 2); hold on;
    plot(spd_meas.Time*1000, squeeze(spd_meas.Data), 'b-', 'LineWidth', 2);
    yline(13650, 'k:', 'Base Speed n_{base} = 13,650 rpm', 'LineWidth', 1.5);
    grid on;
    ylabel('Speed [rpm]', 'FontSize', 11, 'FontWeight', 'bold');
    title('PMSM FOC Drive: Clean & Optimized Speed Tracking Response', 'FontSize', 13, 'FontWeight', 'bold');
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
    
    saveas(f, 'clean_optimized_speed_tracking.png');
    close(f);
    
    fprintf('Saved clean plot to clean_optimized_speed_tracking.png\n');
end

function val = getSignalValues(logs, name)
    elem = logs.get(name);
    if isa(elem, 'Simulink.SimulationData.Dataset')
        val = elem{1}.Values;
    else
        val = elem.Values;
    end
end
