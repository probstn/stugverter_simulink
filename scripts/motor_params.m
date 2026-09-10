%% motor_params.m
% Fischer TI085-052-070-04B7S-07S04BE2 Interior Permanent Magnet Synchronous Motor (IPMSM)

%% Datasheet / Motor Parameters
pmsm.P        = 4;          % Number of pole pairs
pmsm.Rs       = 0.126;      % Stator phase resistance [Ohm]
pmsm.Lph      = 0.393e-3;   % Nominal phase inductance [H]

% IPMSM Saliency Parameters (Lq > Ld for Interior PMSM)
pmsm.Ld       = 0.35e-3;    % Direct-axis inductance [H]
pmsm.Lq       = 0.55e-3;    % Quadrature-axis inductance [H]
pmsm.Ldq      = [pmsm.Ld, pmsm.Lq]; % [Ld, Lq] inductance vector [H]

% Back-EMF & Flux linkage
pmsm.Ke_data  = 0.296;      % BEMF constant [Vrms_LL/(rad/s)]
% Permanent magnet flux linkage [Wb]: lambda_pm = Ke_data / (sqrt(1.5)*P)
pmsm.fl       = 0.0604;     % PM flux linkage [Wb]
% Fischer Ke: Vrms_LL/(rad/s) -> Vpeak_LL/krpm
pmsm.Ke       = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);

% Datasheet limits are retained for reference. The active values below are
% deliberately reduced for the 40 V / 1 A commissioning supply.
pmsm.V_datasheet = 600;
pmsm.I_datasheet = 86.0;
pmsm.T_peak_datasheet = 29.1;
pmsm.N_base_datasheet = 9500;
pmsm.N_max_datasheet = 20000;

% Active low-energy commissioning limits (must remain below the PSU limits).
pmsm.V_rated  = 40;         % Fixed assumed DC bus voltage [V] (no sensor yet)
pmsm.I_rated  = 0.80;       % Peak phase-current command limit [A]
pmsm.T_peak   = 0.25;       % Torque command limit [Nm], below 0.8 A equivalent
pmsm.T_rated  = 11.1;       % Nominal continuous torque [Nm]
pmsm.N_base   = 600;        % Conservative 40 V commissioning base speed [rpm]
pmsm.N_max    = 800;        % Commissioning speed ceiling [rpm]

% Mechanical Parameters: [Inertia (kg*m^2), Viscous Damping (Nm/(rad/s)), Static Friction (Nm)]
pmsm.J        = 0.33e-3;    % Rotor inertia [kg*m^2]
pmsm.B        = 1e-4;       % Viscous damping coefficient [Nm/(rad/s)]
pmsm.mechanical = [pmsm.J, pmsm.B, 0];
