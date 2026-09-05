%% inspect_current_ctrl_detail.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_controller');

blks = find_system('foc_controller', 'SearchDepth', 2);
for i = 2:length(blks)
    fprintf('[%d] %s (%s)\n', i, blks{i}, get_param(blks{i}, 'BlockType'));
end
