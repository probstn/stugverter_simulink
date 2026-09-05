% inspect_all_variants.m
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
motor_sys = [mtpa_blk '/Motor_System'];

blks = find_system(motor_sys, 'MatchFilter', @Simulink.match.allVariants);
disp('All variants in Motor_System:');
for i = 1:length(blks)
    fprintf('  %s [%s]\n', blks{i}, get_param(blks{i}, 'BlockType'));
end
