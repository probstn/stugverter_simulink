%% motor.m
% Fischer TI085-052-070-04B7S-07S04BE2

%% Datasheet parameters

pmsm.P        = 4;          % Pole pairs
pmsm.Rs       = 0.126;      % Phase resistance [Ohm]
pmsm.Lph      = 0.393e-3;   % Phase inductance [H]
pmsm.Ke_data  = 0.296;      % BEMF constant [Vrms_LL/(rad/s)]
pmsm.J        = 0.33e-3;    % Rotor inertia [kg*m^2]
pmsm.V_rated  = 600;
pmsm.I_rated  = 50.0;

%% Derived parameters

% Assume Ld = Lq because the datasheet only specifies Lph
pmsm.Ldq = [pmsm.Lph pmsm.Lph];

% Convert Fischer Ke:
% Vrms_LL/(rad/s)
%
% -> Vpeak_LL/krpm
pmsm.Ke = pmsm.Ke_data * sqrt(2) * (1000 * 2*pi/60);

% Mechanical parameters:
% [inertia, viscous damping, static friction]
% Damping and friction are not specified in the datasheet.
pmsm.mechanical = [pmsm.J 0 0];