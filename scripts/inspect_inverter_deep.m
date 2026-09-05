%% inspect_inverter_deep.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_plant');

sys = 'foc_plant/Average-Value Inverter';
blks = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on');
for i = 1:length(blks)
    fprintf('[%d] %s (%s)\n', i, blks{i}, get_param(blks{i}, 'BlockType'));
    if strcmp(get_param(blks{i}, 'BlockType'), 'Gain')
        fprintf('  Gain: %s\n', get_param(blks{i}, 'Gain'));
    end
end
