% inspect_inverter.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
inv_sys = 'foc_plant/Average-Value Inverter';
lines = get_param(inv_sys, 'Lines');
fprintf('Lines in Average-Value Inverter:\n');
for l = 1:length(lines)
    describe_l(lines(l));
end

function describe_l(l)
    if l.SrcBlock ~= -1
        src = sprintf('%s/%d', get_param(l.SrcBlock, 'Name'), l.SrcPort);
    else
        src = 'none';
    end
    if l.DstBlock ~= -1
        dst = sprintf('%s/%d', get_param(l.DstBlock, 'Name'), l.DstPort);
        fprintf('  %s -> %s\n', src, dst);
    end
    if isfield(l, 'Branch') && ~isempty(l.Branch)
        for b = 1:length(l.Branch)
            describe_l(l.Branch(b));
        end
    end
end
