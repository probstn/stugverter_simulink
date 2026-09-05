% explore_mcb_blocks.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
blks = find_system('mcbcontrolslib', 'SearchDepth', 1, 'Type', 'Block');
for i = 1:length(blks)
    fprintf('MCB Block: %s\n', get_param(blks{i}, 'Name'));
end
