% inspect_ctrl_bus.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_controller');
bs = 'foc_controller/Bus Selector';
fprintf('Bus Selector OutputSignals in foc_controller: %s\n', get_param(bs, 'OutputSignals'));

lines = get_param('foc_controller', 'Lines');
for l = 1:length(lines)
    if lines(l).SrcBlock ~= -1
        name = get_param(lines(l).SrcBlock, 'Name');
        if strcmp(name, 'Bus Selector')
            describe_conn_clean(lines(l));
        end
    end
end

function describe_conn_clean(l)
    src = sprintf('%s (port %d)', get_param(l.SrcBlock, 'Name'), l.SrcPort);
    if l.DstBlock ~= -1
        dst = sprintf('%s (port %d)', get_param(l.DstBlock, 'Name'), l.DstPort);
        fprintf('  %s --> %s\n', src, dst);
    end
    if isfield(l, 'Branch') && ~isempty(l.Branch)
        for b = 1:length(l.Branch)
            describe_conn_clean(l.Branch(b));
        end
    end
end
