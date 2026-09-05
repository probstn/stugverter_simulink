%% fix_plant_flux_linkage.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_plant');

blk = 'foc_plant/Interior PMSM';
set_param(blk, 'KConstText', 'Permanent flux linkage constant (lambda_pm):');
set_param(blk, 'lambda_pm', 'pmsm.fl');

% Force mask evaluation
set_param(blk, 'KConst', 'pmsm.fl');

save_system('foc_plant');
disp('Successfully configured Interior PMSM in foc_plant:');
disp(['lambda_pm: ', get_param(blk, 'lambda_pm')]);
disp(['lambda_pm_calc: ', get_param(blk, 'lambda_pm_calc')]);
