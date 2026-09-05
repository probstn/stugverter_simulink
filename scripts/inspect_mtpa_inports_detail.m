%% inspect_mtpa_inports_detail.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');

blks = find_system('foc_system/MTPA Control Reference', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Inport');
for i = 1:length(blks)
    p = get_param(blks{i}, 'Port');
    fprintf('Inport [%s]: %s\n', p, blks{i});
end

% Check Gains inside MTPA Control Reference
gains = find_system('foc_system/MTPA Control Reference', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Gain');
for i = 1:length(gains)
    fprintf('Gain block: %s | Gain value: %s\n', gains{i}, get_param(gains{i}, 'Gain'));
end
