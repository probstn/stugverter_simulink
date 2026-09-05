% test_mtpa_math.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

% Let's test what MTPA Control Reference produces for Tref = 1 Nm, 5 Nm, 10 Nm, 20 Nm at 1000 RPM
% Parameters:
P = 4;
Rs = 0.126;
Ld = 0.35e-3;
Lq = 0.55e-3;
fl = 0.0604;
I_rated = 86;
V_dc = 600;

% Let's check MTPA equation:
% For IPMSM: Te = 1.5 * P * [fl * iq + (Ld - Lq) * id * iq]
% MTPA trajectory relates id to iq:
% id = (fl / (2*(Lq - Ld))) - sqrt( (fl / (2*(Lq - Ld)))^2 + iq^2 ) (where id <= 0)
% Or in terms of current magnitude Is and gamma (angle):
% Te(Is, gamma) = 1.5 * P * [fl * Is * cos(gamma) + 0.5 * (Lq - Ld) * Is^2 * sin(2*gamma)]

% Let's check what MTPA block calculates:
delta_L = Lq - Ld; % 0.20 mH
fprintf('delta_L = %.4f mH\n', delta_L*1e3);
fprintf('fl / (2*delta_L) = %.2f A\n', fl / (2*delta_L));

% If iq = 10 A:
iq = 10;
id = (fl / (2*delta_L)) - sqrt((fl/(2*delta_L))^2 + iq^2);
fprintf('For iq = %.1f A: id = %.2f A\n', iq, id);
Te = 1.5 * P * (fl * iq + (Ld - Lq) * id * iq);
fprintf('Resulting Torque = %.2f Nm\n', Te);
