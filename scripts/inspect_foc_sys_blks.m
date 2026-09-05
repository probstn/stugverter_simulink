% inspect_foc_sys_blks.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('foc_system');
blks = find_system('foc_system', 'SearchDepth', 1);
fprintf('Blocks in foc_system:\n');
for i = 1:length(blks)
    if strcmp(blks{i}, 'foc_system'), continue; end
    fprintf('  %s [%s]\n', get_param(blks{i}, 'Name'), get_param(blks{i}, 'BlockType'));
end
