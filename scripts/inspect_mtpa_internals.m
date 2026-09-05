%% inspect_mtpa_internals.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');

blks = find_system('foc_system/MTPA Control Reference', 'LookUnderMasks', 'all', 'FollowLinks', 'on');
for i = 1:length(blks)
    fprintf('[%d] %s (Type: %s)\n', i, blks{i}, get_param(blks{i}, 'BlockType'));
end
