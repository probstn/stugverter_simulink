%% inspect_ctrl_gains_detail.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_controller');

disp(['Gain_Vd_to_pu: ', get_param('foc_controller/Gain_Vd_to_pu', 'Gain')]);
disp(['Gain_Vq_to_pu: ', get_param('foc_controller/Gain_Vq_to_pu', 'Gain')]);

id_pi = find_system('foc_controller/Id Controller', 'LookUnderMasks', 'all', 'MaskType', 'PID 1dof');
iq_pi = find_system('foc_controller/Iq Controller', 'LookUnderMasks', 'all', 'MaskType', 'PID 1dof');

disp(['Id PI: ', id_pi{1}]);
disp(['  P: ', get_param(id_pi{1}, 'P'), ' I: ', get_param(id_pi{1}, 'I')]);
disp(['  Upper: ', get_param(id_pi{1}, 'UpperSaturationLimit'), ' Lower: ', get_param(id_pi{1}, 'LowerSaturationLimit')]);

disp(['Iq PI: ', iq_pi{1}]);
disp(['  P: ', get_param(iq_pi{1}, 'P'), ' I: ', get_param(iq_pi{1}, 'I')]);
disp(['  Upper: ', get_param(iq_pi{1}, 'UpperSaturationLimit'), ' Lower: ', get_param(iq_pi{1}, 'LowerSaturationLimit')]);
