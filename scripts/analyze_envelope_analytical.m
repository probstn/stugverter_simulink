%% analyze_envelope_analytical.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
run('motor.m');

V_max = pmsm.V_rated / sqrt(3); % Max phase voltage peak (346.41 V)
I_max = pmsm.I_rated;           % Max phase current peak (86 A)
P = pmsm.P;
Ld = pmsm.Ld;
Lq = pmsm.Lq;
fl = pmsm.fl;

% MTPA Point
dL = Lq - Ld;
id_mtpa = (fl - sqrt(fl^2 + 8 * dL^2 * I_max^2)) / (4 * dL);
iq_mtpa = sqrt(I_max^2 - id_mtpa^2);
T_peak_calc = 1.5 * P * (fl * iq_mtpa + (Ld - Lq) * id_mtpa * iq_mtpa);

% Speed where MTPA point hits voltage limit:
V_mtpa = sqrt((fl + Ld*id_mtpa)^2 + (Lq*iq_mtpa)^2);
we_base = V_max / V_mtpa;
N_base_loaded = (we_base / P) * (60 / (2*pi));

fprintf('=== Fischer IPMSM Analytical Characteristics ===\n');
fprintf('MTPA Peak Current: id = %.2f A, iq = %.2f A (|Is| = %.1f A)\n', id_mtpa, iq_mtpa, sqrt(id_mtpa^2 + iq_mtpa^2));
fprintf('MTPA Peak Torque:  %.2f Nm (Datasheet: %.1f Nm)\n', T_peak_calc, pmsm.T_peak);
fprintf('Loaded Base Speed (at 86 A peak): %.1f RPM\n', N_base_loaded);
fprintf('No-Load Base Speed:               %.1f RPM\n', (V_max / fl / P) * (60 / (2*pi)));

% Check FW points at different speeds
test_speeds = [10000, 12000, 14000, 16000, 18000, 20000];
fprintf('\n--- Field Weakening Capability at Speeds ---\n');
for N = test_speeds
    we = (N * 2*pi / 60) * P;
    if N <= N_base_loaded
        id = id_mtpa;
        iq = iq_mtpa;
        T = T_peak_calc;
    else
        % Solve quadratic for id
        A_q = Ld^2 - Lq^2;
        B_q = 2 * fl * Ld;
        C_q = fl^2 + Lq^2 * I_max^2 - (V_max / we)^2;
        
        disc = B_q^2 - 4 * A_q * C_q;
        if disc >= 0
            % We want the root with id < 0
            id1 = (-B_q + sqrt(disc)) / (2 * A_q);
            id2 = (-B_q - sqrt(disc)) / (2 * A_q);
            % A_q is negative (Ld < Lq), so (-B_q - sqrt) / (negative) is positive, (-B_q + sqrt) / (negative) is negative
            id = id1;
            iq = sqrt(max(0, I_max^2 - id^2));
            T = 1.5 * P * (fl * iq + (Ld - Lq) * id * iq);
        else
            id = -fl / Ld;
            iq = 0;
            T = 0;
        end
    end
    fprintf('  Speed: %5d RPM | id = %6.2f A | iq = %5.2f A | Max Torque = %5.2f Nm | Mech Power = %5.2f kW\n', ...
        N, id, iq, T, T * (N * 2*pi / 60) / 1000);
end
