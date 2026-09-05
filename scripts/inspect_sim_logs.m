%% inspect_sim_logs.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');
set_param('foc_system', 'StopTime', '0.1');
out = sim('foc_system');
logs = out.logsout;
fprintf('Number of logged elements: %d\n', logs.numElements);
for i = 1:logs.numElements
    el = logs{i};
    fprintf('  [%d] Name: "%s", BlockPath: "%s"\n', i, el.Name, el.BlockPath.getBlock(1));
end
