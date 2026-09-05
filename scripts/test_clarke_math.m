% test_clarke_math.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
ct = 'mcbcontrolslib/Clarke Transform';
blks = find_system(ct, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(blks)
    fprintf('  Clarke blk: %s [%s]\n', blks{i}, get_param(blks{i}, 'BlockType'));
end
