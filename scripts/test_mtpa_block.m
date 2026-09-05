% test_mtpa_block.m
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

% Check if wm port inside MTPA has a gain for mech2elec
find_wm = find_system(mtpa_blk, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Name', 'wm');
for i = 1:length(find_wm)
    fprintf('Block wm: %s\n', find_wm{i});
end

% Look at Gain blocks connected after wm
blks_inside = find_system([mtpa_blk '/Motor_System/Interior PMSM'], 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(blks_inside)
    if contains(blks_inside{i}, 'Gain') || contains(blks_inside{i}, 'Product')
        fprintf('  %s: Gain=%s\n', blks_inside{i}, get_param(blks_inside{i}, 'Gain'));
    end
end
