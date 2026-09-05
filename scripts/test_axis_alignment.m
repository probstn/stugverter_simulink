% test_axis_alignment.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
pmsm_blk = 'foc_plant/Interior PMSM';

% Check mask help / description / internals of autolibpmsminterior/Interior PMSM
disp('--- Interior PMSM block mask ---');
disp(get_param(pmsm_blk, 'MaskHelp'));
disp(get_param(pmsm_blk, 'MaskDescription'));

% Check equations inside Interior PMSM Core
core_blks = find_system(pmsm_blk, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(core_blks)
    if contains(core_blks{i}, 'Transform') || contains(core_blks{i}, 'Park') || contains(core_blks{i}, 'Clarke') || contains(core_blks{i}, 'Angle')
        fprintf('  %s [%s]\n', core_blks{i}, get_param(core_blks{i}, 'BlockType'));
    end
end
