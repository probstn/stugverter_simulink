%% analyze_torque_speed_envelope.m
% Calculates and plots the exact theoretical MTPA & Field Weakening envelope

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
run('motor.m');

V_max = pmsm.V_rated / sqrt(3); % Max phase voltage peak (346.4 V)
I_max = pmsm.I_rated;           % Max phase current peak (86 A)
P = pmsm.P;
Ld = pmsm.Ld;
Lq = pmsm.Lq;
fl = pmsm.fl;

speed_rpm_vec = linspace(100, 20000, 200);
T_max_vec = zeros(size(speed_rpm_vec));
id_opt_vec = zeros(size(speed_rpm_vec));
iq_opt_vec = zeros(size(speed_rpm_vec));

for i = 1:length(speed_rpm_vec)
    N = speed_rpm_vec(i);
    we = (N * 2*pi / 60) * P; % Electrical rad/s
    
    % Optimize (id, iq) to maximize torque subject to:
    % 1) id^2 + iq^2 <= I_max^2
    % 2) (we*(fl + Ld*id))^2 + (we*Lq*iq)^2 <= V_max^2
    % Torque: 1.5 * P * (fl * iq + (Ld - Lq) * id * iq)
    
    cost_fn = @(x) -1.5 * P * (fl * x(2) + (Ld - Lq) * x(1) * x(2));
    nonlcon = @(x) deal([x(1)^2 + x(2)^2 - I_max^2; ...
                         (we*(fl + Ld*x(1)))^2 + (we*Lq*x(2))^2 - V_max^2], []);
    
    x0 = [-10, 50];
    opts = optimoptions('fmincon', 'Display', 'off');
    [x_opt, fval] = fmincon(cost_fn, x0, [], [], [], [], [-I_max, 0], [0, I_max], nonlcon, opts);
    
    T_max_vec(i) = -fval;
    id_opt_vec(i) = x_opt(1);
    iq_opt_vec(i) = x_opt(2);
end

fprintf('=== Fischer IPMSM Capability Envelope ===\n');
fprintf('Peak Torque at 5,000 RPM (MTPA): %.2f Nm (id = %.1f A, iq = %.1f A)\n', T_max_vec(50), id_opt_vec(50), iq_opt_vec(50));
fprintf('Peak Torque at 10,000 RPM:       %.2f Nm (id = %.1f A, iq = %.1f A)\n', interp1(speed_rpm_vec, T_max_vec, 10000), interp1(speed_rpm_vec, id_opt_vec, 10000), interp1(speed_rpm_vec, iq_opt_vec, 10000));
fprintf('Peak Torque at 15,000 RPM (FW):   %.2f Nm (id = %.1f A, iq = %.1f A)\n', interp1(speed_rpm_vec, T_max_vec, 15000), interp1(speed_rpm_vec, id_opt_vec, 15000), interp1(speed_rpm_vec, iq_opt_vec, 15000));
fprintf('Peak Torque at 18,000 RPM (FW):   %.2f Nm (id = %.1f A, iq = %.1f A)\n', interp1(speed_rpm_vec, T_max_vec, 18000), interp1(speed_rpm_vec, id_opt_vec, 18000), interp1(speed_rpm_vec, iq_opt_vec, 18000));
fprintf('Peak Torque at 20,000 RPM (FW):   %.2f Nm (id = %.1f A, iq = %.1f A)\n', interp1(speed_rpm_vec, T_max_vec, 20000), interp1(speed_rpm_vec, id_opt_vec, 20000), interp1(speed_rpm_vec, iq_opt_vec, 20000));
