% test_voltage_scaling.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_controller');
load_system('foc_plant');

% Let's test PWM Reference Generator and Average-Value Inverter mapping:
% In foc_controller:
% If Id Controller outputs Vd = 100 V, Vq = 0 V at theta_e = 0:
% Valpha = 100 V, Vbeta = 0 V.
% Gain_Vd_to_pu = sqrt(3)/600 = 0.00288675 -> Valpha_pu = 0.288675.
% What duty cycles does PWM Reference Generator produce?
% And what phase voltages does Average-Value Inverter produce with those duty cycles?

disp('PWM Reference Generator parameters:');
pwm_names = get_param('foc_controller/PWM Reference Generator', 'MaskNames');
for i = 1:length(pwm_names)
    fprintf('  %s = %s\n', pwm_names{i}, get_param('foc_controller/PWM Reference Generator', pwm_names{i}));
end
