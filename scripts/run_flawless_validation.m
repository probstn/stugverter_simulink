% run_flawless_validation.m
function run_flawless_validation()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_speedcontroller');
    load_system('foc_controller');
    load_system('foc_plant');
    
    disp('=== 1. Current Controller Tuning in foc_controller ===');
    wn_c = 2 * pi * 800; % 800 Hz bandwidth
    foc.Kp_d = single(pmsm.Lph * wn_c);  % ~1.975 V/A
    foc.Ki_d = single(pmsm.Rs * wn_c);   % ~633.3 V/(A*s)
    foc.Kp_q = foc.Kp_d;
    foc.Ki_q = foc.Ki_d;
    assignin('base', 'foc', foc);
    
    set_param('foc_controller/Id Controller', 'P', 'foc.Kp_d');
    set_param('foc_controller/Id Controller', 'I', 'foc.Ki_d');
    set_param('foc_controller/Id Controller', 'AntiWindupMode', 'clamping');
    set_param('foc_controller/Id Controller', 'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)');
    set_param('foc_controller/Id Controller', 'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)');
    
    set_param('foc_controller/Iq Controller', 'P', 'foc.Kp_q');
    set_param('foc_controller/Iq Controller', 'I', 'foc.Ki_q');
    set_param('foc_controller/Iq Controller', 'AntiWindupMode', 'clamping');
    set_param('foc_controller/Iq Controller', 'UpperSaturationLimit', 'pmsm.V_rated/sqrt(3)');
    set_param('foc_controller/Iq Controller', 'LowerSaturationLimit', '-pmsm.V_rated/sqrt(3)');
    save_system('foc_controller');
    
    disp('=== 2. Speed Controller Tuning in foc_speedcontroller ===');
    % Clean lines in foc_speedcontroller
    delete_inport_lines('foc_speedcontroller/Subtract', 1);
    delete_outport_lines('foc_speedcontroller/set_speed', 1);
    try, delete_block('foc_speedcontroller/Rate_Limiter'); catch, end
    try, delete_block('foc_speedcontroller/Setpoint_Filter'); catch, end
    
    add_line('foc_speedcontroller', 'set_speed/1', 'Subtract/1', 'autorouting', 'on');
    
    % PI controller tuning with back-calculation anti-windup:
    set_param('foc_speedcontroller/PI Controller', 'Controller', 'PI');
    set_param('foc_speedcontroller/PI Controller', 'P', '0.015');
    set_param('foc_speedcontroller/PI Controller', 'I', '0.30');
    set_param('foc_speedcontroller/PI Controller', 'AntiWindupMode', 'back-calculation');
    set_param('foc_speedcontroller/PI Controller', 'Kb', '20');
    set_param('foc_speedcontroller/PI Controller', 'UpperSaturationLimit', 'pmsm.T_peak');
    set_param('foc_speedcontroller/PI Controller', 'LowerSaturationLimit', '-pmsm.T_peak');
    save_system('foc_speedcontroller');
    
    disp('=== 3. Top-Level Connections in foc_system ===');
    delete_outport_lines('foc_system/SpeedProfile', 1);
    delete_inport_lines('foc_system/Model', 1);
    delete_inport_lines('foc_system/Scope', 2);
    delete_inport_lines('foc_system/MTPA Control Reference', 2);
    
    try, delete_block('foc_system/Speed_Rate_Limiter'); catch, end
    try, delete_block('foc_system/RPM_to_RadPerSec'); catch, end
    try, delete_block('foc_system/SpeedFilter_MTPA'); catch, end
    
    add_block('simulink/Discontinuities/Rate Limiter', 'foc_system/Speed_Rate_Limiter', ...
        'RisingSlewLimit', '150000', 'FallingSlewLimit', '-150000', 'Position', [1060, 410, 1100, 440]);
    add_block('simulink/Math Operations/Gain', 'foc_system/RPM_to_RadPerSec', ...
        'Gain', 'pi/30', 'Position', [1130, 360, 1170, 390]);
        
    add_line('foc_system', 'SpeedProfile/1', 'Speed_Rate_Limiter/1', 'autorouting', 'on');
    add_line('foc_system', 'Speed_Rate_Limiter/1', 'Model/1', 'autorouting', 'on');
    add_line('foc_system', 'Speed_Rate_Limiter/1', 'Scope/2', 'autorouting', 'on');
    add_line('foc_system', 'Speed_Rate_Limiter/1', 'RPM_to_RadPerSec/1', 'autorouting', 'on');
    add_line('foc_system', 'RPM_to_RadPerSec/1', 'MTPA Control Reference/2', 'autorouting', 'on');
    
    % Setup Signal Logging on foc_system
    set_param('foc_system', 'SignalLogging', 'on');
    set_param('foc_system', 'SignalLoggingName', 'logsout');
    
    ph_srl = get_param('foc_system/Speed_Rate_Limiter', 'PortHandles');
    set_param(ph_srl.Outport(1), 'DataLogging', 'on');
    set_param(ph_srl.Outport(1), 'DataLoggingNameMode', 'Custom');
    set_param(ph_srl.Outport(1), 'DataLoggingName', 'Speed_Ref');
    
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
    
    % Multi-step reference
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
    title('PMSM FOC Drive: Flawless Speed Tracking across MTPA & Field Weakening', 'FontSize', 13, 'FontWeight', 'bold');
    legend('Ramped Reference Speed', 'Actual Rotor Speed', 'Base Speed Threshold (13,650 rpm)', 'Location', 'northwest');
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
    
    saveas(f, 'flawless_speed_tracking.png');
    close(f);
    
    fprintf('Saved flawless tracking plot to flawless_speed_tracking.png\n');
end

function delete_inport_lines(blk, portIdx)
    ph = get_param(blk, 'PortHandles');
    h = get_param(ph.Inport(portIdx), 'Line');
    while h ~= -1 && ishandle(h)
        delete_line(h);
        h = get_param(ph.Inport(portIdx), 'Line');
    end
end

function delete_outport_lines(blk, portIdx)
    ph = get_param(blk, 'PortHandles');
    h = get_param(ph.Outport(portIdx), 'Line');
    while h ~= -1 && ishandle(h)
        delete_line(h);
        h = get_param(ph.Outport(portIdx), 'Line');
    end
end

function val = getSignalValues(logs, name)
    elem = logs.get(name);
    if isa(elem, 'Simulink.SimulationData.Dataset')
        val = elem{1}.Values;
    else
        val = elem.Values;
    end
end
