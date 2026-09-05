% inspect_plant_connections.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
bc = 'foc_plant/Bus Creator';
pmsm_blk = 'foc_plant/Interior PMSM';

% Check ports of Interior PMSM
fprintf('Interior PMSM Ports: %s\n', mat2str(get_param(pmsm_blk, 'Ports')));

% Check lines in foc_plant
lines = get_param('foc_plant', 'Lines');
fprintf('Lines in foc_plant:\n');
for l = 1:length(lines)
    disp_l_full(lines(l));
end

% Check Bus Creator inputs
bc_in = get_param(bc, 'PortConnectivity');
for i = 1:length(bc_in)
    fprintf('Bus Creator input %d connects from: %s (port %d)\n', ...
        i, get_param(bc_in(i).SrcBlock, 'Name'), bc_in(i).SrcPort+1);
end

function disp_l_full(l)
    if l.SrcBlock ~= -1
        src = sprintf('%s (port %d)', get_param(l.SrcBlock, 'Name'), l.SrcPort);
    else
        src = 'none';
    end
    if l.DstBlock ~= -1
        dst = sprintf('%s (port %d)', get_param(l.DstBlock, 'Name'), l.DstPort);
        fprintf('  %s --> %s\n', src, dst);
    end
    if isfield(l, 'Branch') && ~isempty(l.Branch)
        for b = 1:length(l.Branch)
            disp_l_full(l.Branch(b));
        end
    end
end
