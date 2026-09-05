% test_speed_sub.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_speedcontroller');
sub = 'foc_speedcontroller/Subtract';
fprintf('Subtract block inputs: %s\n', get_param(sub, 'Inputs'));

% Check port connectivity
c = get_param(sub, 'PortConnectivity');
for i = 1:length(c)
    if ~isempty(c(i).SrcBlock)
        fprintf('  Input %d from %s (port %d)\n', i, get_param(c(i).SrcBlock, 'Name'), c(i).SrcPort+1);
    end
end

% Also check foc_system connections to foc_speedcontroller (Model)
load_system('foc_system');
mdl_blk = 'foc_system/Model';
c_mdl = get_param(mdl_blk, 'PortConnectivity');
for i = 1:length(c_mdl)
    if ~isempty(c_mdl(i).SrcBlock)
        fprintf('  foc_system Model Inport %d connects from %s (port %d)\n', ...
            i, get_param(c_mdl(i).SrcBlock, 'Name'), c_mdl(i).SrcPort+1);
    end
end
