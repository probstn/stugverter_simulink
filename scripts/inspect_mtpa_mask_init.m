% inspect_mtpa_mask_init.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
mtpa_blk = 'foc_system/MTPA Control Reference';

% Look at Motor_System sub-blocks
motor_sys = [mtpa_blk '/Motor_System'];
try
    subsys = find_system(motor_sys, 'SearchDepth', 1);
    disp('Subsystems inside Motor_System:');
    disp(subsys);
catch ME
    disp(ME.message);
end

% Check which callback function is used
which mcb.internal.PMSMRefCurrentGeneratorCb
