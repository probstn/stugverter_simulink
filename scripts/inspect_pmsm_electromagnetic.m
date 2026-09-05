% inspect_pmsm_electromagnetic.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
em = 'foc_plant/Interior PMSM/PMSM Torque Input Continuous/PMSM Torque Input Core/PMSM Electromagnetic';

% Find all blocks in PMSM Electromagnetic
blks = find_system(em, 'SearchDepth', 1, 'Type', 'Block');
for i = 1:length(blks)
    fprintf('EM blk: %s [%s]\n', blks{i}, get_param(blks{i}, 'BlockType'));
end

% Check lines
lines = get_param(em, 'Lines');
for l = 1:length(lines)
    if lines(l).SrcBlock ~= -1 && lines(l).DstBlock ~= -1
        src = get_param(lines(l).SrcBlock, 'Name');
        dst = get_param(lines(l).DstBlock, 'Name');
        fprintf('  %s -> %s\n', src, dst);
    end
end
