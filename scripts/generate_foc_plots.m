%% generate_foc_plots.m
% Generates verification plots for IPMSM FOC (MTPA + Field Weakening)

rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('init.m');
load_system('foc_system');

% Run multi-regime simulation: 0 -> 8000 RPM (MTPA) -> 18000 RPM (FW) -> 6000 RPM
set_param('foc_system', 'StopTime', '0.90');
out = sim('foc_system');
logs = out.logsout;

spd_meas_ts = logs.get('spd_meas_rads').Values;
id_ref_ts   = logs.get('id_ref').Values;
iq_ref_ts   = logs.get('iq_ref').Values;
id_act_ts   = logs.get('id_actual').Values;
iq_act_ts   = logs.get('iq_actual').Values;
torque_ts   = logs.get('Torque_cmd').Values;

% Speed reference
try
    spd_ref_ts = logs.get('spd_ref_rpm').Values;
    t_ref = spd_ref_ts.Time * 1000;
    d_ref = squeeze(spd_ref_ts.Data);
catch
    t_ref = sp_ts.Time * 1000;
    d_ref = squeeze(sp_ts.Data);
end

% Create Figure
fig = figure('Position', [100, 100, 1000, 900], 'Color', 'w', 'Visible', 'off');

% Subplot 1: Speed Tracking
subplot(4, 1, 1);
plot(t_ref, d_ref, 'k--', 'LineWidth', 1.5); hold on;
plot(spd_meas_ts.Time * 1000, squeeze(spd_meas_ts.Data) * (30/pi), 'b-', 'LineWidth', 1.2);
yline(pmsm.N_base, 'r:', 'LineWidth', 1.2, 'Label', sprintf('N_{base} = %d RPM', pmsm.N_base));
grid on;
title('IPMSM Speed Tracking (MTPA & Field Weakening)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Speed [RPM]', 'FontSize', 10);
legend({'Reference Speed', 'Actual Speed', 'Base Speed (FW threshold)'}, 'Location', 'southeast');
xlim([0, 900]);

% Subplot 2: d-axis and q-axis Reference Currents
subplot(4, 1, 2);
plot(id_ref_ts.Time * 1000, squeeze(id_ref_ts.Data), 'r-', 'LineWidth', 1.5); hold on;
plot(iq_ref_ts.Time * 1000, squeeze(iq_ref_ts.Data), 'b-', 'LineWidth', 1.5);
yline(0, 'k:');
grid on;
title('MTPA & Field Weakening Current References (i_d^*, i_q^*)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current [A]', 'FontSize', 10);
legend({'i_d^* (Direct-axis / Demag)', 'i_q^* (Quadrature-axis / Torque)'}, 'Location', 'east');
xlim([0, 900]);

% Subplot 3: Actual Measured vs Reference Current Tracking
subplot(4, 1, 3);
plot(id_ref_ts.Time * 1000, squeeze(id_ref_ts.Data), 'r--', 'LineWidth', 1.2); hold on;
plot(id_act_ts.Time * 1000, squeeze(id_act_ts.Data), 'r-', 'LineWidth', 0.8);
plot(iq_ref_ts.Time * 1000, squeeze(iq_ref_ts.Data), 'b--', 'LineWidth', 1.2);
plot(iq_act_ts.Time * 1000, squeeze(iq_act_ts.Data), 'b-', 'LineWidth', 0.8);
grid on;
title('Current Loop Tracking (Reference vs Measured)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current [A]', 'FontSize', 10);
legend({'i_d^* ref', 'i_d act', 'i_q^* ref', 'i_q act'}, 'Location', 'east');
xlim([0, 900]);

% Subplot 4: Torque Command & Stator Current Magnitude
subplot(4, 1, 4);
id_act_data = squeeze(id_act_ts.Data);
iq_act_data = squeeze(iq_act_ts.Data);
id_ref_data = squeeze(id_ref_ts.Data);
iq_ref_data = squeeze(iq_ref_ts.Data);
I_mag_ref = sqrt(id_ref_data.^2 + iq_ref_data.^2);

yyaxis left;
plot(torque_ts.Time * 1000, squeeze(torque_ts.Data), 'm-', 'LineWidth', 1.2);
ylabel('Torque Cmd [Nm]', 'FontSize', 10);

yyaxis right;
plot(id_ref_ts.Time * 1000, I_mag_ref, 'k--', 'LineWidth', 1.2); hold on;
yline(pmsm.I_rated, 'r--', 'LineWidth', 1.2, 'Label', sprintf('I_{limit} = %.1f A', pmsm.I_rated));
ylabel('Stator Current |I_s^*| [A]', 'FontSize', 10);
grid on;
title('Torque Command and Stator Current Magnitude', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time [ms]', 'FontSize', 10);
xlim([0, 900]);

% Save plot to artifact directory
artifactDir = '/Users/niklasprobst/.gemini/antigravity/brain/e2a4194e-0e21-45c9-a91d-ee67e76c8861';
savePath = fullfile(artifactDir, 'foc_ipmsm_validation.png');
exportgraphics(fig, savePath, 'Resolution', 200);
fprintf('Figure saved to: %s\n', savePath);

% Trajectory Plot in id-iq Plane
fig2 = figure('Position', [150, 150, 700, 600], 'Color', 'w', 'Visible', 'off');
theta = linspace(0, 2*pi, 200);
plot(pmsm.I_rated * cos(theta), pmsm.I_rated * sin(theta), 'k--', 'LineWidth', 1.2); hold on;

% MTPA trajectory line
i_s_vec = linspace(0, pmsm.I_rated, 100);
d_L = pmsm.Lq - pmsm.Ld;
id_mtpa = (pmsm.fl - sqrt(pmsm.fl^2 + 8 * (d_L)^2 .* (i_s_vec.^2))) ./ (4 * d_L);
iq_mtpa = sqrt(max(0, i_s_vec.^2 - id_mtpa.^2));
plot(id_mtpa, iq_mtpa, 'g-', 'LineWidth', 2);
plot(id_mtpa, -iq_mtpa, 'g-', 'LineWidth', 2);

% Actual reference trajectory
plot(id_ref_data, iq_ref_data, 'r.', 'MarkerSize', 6);
grid on;
axis equal;
xlim([-pmsm.I_rated*1.1, pmsm.I_rated*1.1]);
ylim([-pmsm.I_rated*1.1, pmsm.I_rated*1.1]);
xlabel('d-axis current i_d [A]', 'FontSize', 11);
ylabel('q-axis current i_q [A]', 'FontSize', 11);
title('IPMSM Current Trajectory in i_d - i_q Plane (MTPA + FW)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Current Limit Circle (86 A)', 'Theoretical MTPA Trajectory', 'Simulated Reference Trajectory'}, 'Location', 'northwest');

savePath2 = fullfile(artifactDir, 'id_iq_trajectory.png');
exportgraphics(fig2, savePath2, 'Resolution', 200);
fprintf('Trajectory figure saved to: %s\n', savePath2);
