%% inspect_fw_condition_deep.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');

sys = 'foc_system/MTPA Control Reference/Motor_System/Interior PMSM/MTPA_FW_iteratorSelection/no_iterators/fast_and_approximate/FW condition';
blks = find_system(sys, 'LookUnderMasks', 'all');
for i = 1:length(blks)
    fprintf('[%d] %s (%s)\n', i, blks{i}, get_param(blks{i}, 'BlockType'));
end
