% inspect_mech_angle.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
ma = 'foc_plant/Interior PMSM/PMSM Torque Input Continuous/PMSM Torque Input Core/Mechanical and Angle';

blks = find_system(ma, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(blks)
    fprintf('MA blk: %s [%s]\n', blks{i}, get_param(blks{i}, 'BlockType'));
    if strcmp(get_param(blks{i}, 'BlockType'), 'Gain')
        fprintf('   Gain = %s\n', get_param(blks{i}, 'Gain'));
    end
end
