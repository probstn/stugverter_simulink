%% apply_flux_and_run.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
blk = 'foc_plant/Interior PMSM';
set_param(blk, 'KConstText', 'Permanent flux linkage constant (lambda_pm):');
set_param(blk, 'lambda_pm', 'pmsm.fl');
set_param(blk, 'lambda_pm_calc', 'pmsm.fl');
save_system('foc_plant');
disp('foc_plant successfully saved with lambda_pm_calc = pmsm.fl');

% Run plot generation
run('generate_foc_plots.m');
