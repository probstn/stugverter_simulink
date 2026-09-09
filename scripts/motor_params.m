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

% Electrical & Thermal Limits
pmsm.V_rated  = 600;        % DC bus voltage [V]
pmsm.I_rated  = 86.0;       % Peak phase current limit [A] (61 Arms = 86.26 Apeak)
pmsm.T_peak   = 29.1;       % Peak torque [Nm]
pmsm.T_rated  = 11.1;       % Nominal continuous torque [Nm]
pmsm.N_base   = 9500;       % Loaded base speed where field weakening begins [rpm] (stator voltage limit under load)
pmsm.N_max    = 20000;      % Maximum operating speed in field weakening [rpm]

% Mechanical Parameters: [Inertia (kg*m^2), Viscous Damping (Nm/(rad/s)), Static Friction (Nm)]
pmsm.J        = 0.33e-3;    % Rotor inertia [kg*m^2]
pmsm.B        = 1e-4;       % Viscous damping coefficient [Nm/(rad/s)]
pmsm.mechanical = [pmsm.J, pmsm.B, 0];
