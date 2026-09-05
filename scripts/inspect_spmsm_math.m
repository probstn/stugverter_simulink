% inspect_spmsm_math.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
mtpa_blk = 'foc_system/MTPA Control Reference';

% Inspect Surface PMSM subsystem
spmsm_sys = [mtpa_blk '/Motor_System/Surface PMSM'];
lines = get_param(spmsm_sys, 'Lines');
disp('Lines in Surface PMSM subsystem:');
for l = 1:length(lines)
    describe_line_simple(lines(l));
end

function describe_line_simple(l)
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
            describe_line_simple(l.Branch(b));
        end
    end
end
