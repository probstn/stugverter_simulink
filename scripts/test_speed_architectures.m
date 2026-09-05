% test_speed_architectures.m
function test_speed_architectures()
    rootDir = pwd;
    addpath(genpath(rootDir));
    run('init.m');
    
    load_system('foc_system');
    load_system('foc_speedcontroller');
    load_system('foc_controller');
    load_system('foc_plant');
    
    disp('=== Testing and Optimizing Speed Control Architecture ===');
    
    % Let's design the optimal gains based on Pole Placement
    % Plant: G(s) = 1 / (J * s) where J = 0.33e-3 kg*m^2
    % Speed is in rad/s: T_e = J * d(omega)/dt
    % If speed controller works in rad/s:
    % omega_n = 2*pi * 15 Hz = 94.2 rad/s (bandwidth)
    % zeta = 1.0 (critically damped, no overshoot!)
    % Kp_omega = 2 * zeta * omega_n * J = 2 * 1.0 * 94.2 * 0.33e-3 = 0.0622 Nm / (rad/s)
    % Ki_omega = omega_n^2 * J = (94.2)^2 * 0.33e-3 = 2.928 Nm / (rad/s * s)
    
    % Since error in foc_speedcontroller is in RPM:
    % e_rad_per_sec = e_rpm * (pi/30)
    % Kp_rpm = Kp_omega * (pi/30) = 0.0622 * 0.10472 = 0.00651 Nm/rpm
    % Ki_rpm = Ki_omega * (pi/30) = 2.928 * 0.10472 = 0.3066 Nm/(rpm*s)
    
    % If using I-P (Proportional on measurement) or 2-DOF PID:
    % In slpidlib / PID Controller:
    % Set Form = 'Parallel', Controller = 'PID', Form = 'Ideal' or 2-DOF PID
    
    fprintf('Calculated optimal critically-damped gains:\n');
    fprintf('  Kp_rpm = 0.0065 Nm/rpm\n');
    fprintf('  Ki_rpm = 0.30 Nm/(rpm*s)\n');
end
