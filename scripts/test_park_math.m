% test_park_math.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
pt_blk = 'mcbcontrolslib/Park Transform';
lines = find_system(pt_blk, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(lines)
    fprintf('  %s [%s]\n', lines{i}, get_param(lines{i}, 'BlockType'));
end
