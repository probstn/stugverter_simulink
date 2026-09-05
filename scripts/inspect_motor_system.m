% inspect_motor_system.m
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

% Check lines inside MTPA Control Reference root
lines = get_param(mtpa_blk, 'Lines');
disp('=== Lines in MTPA Control Reference root ===');
for l = 1:length(lines)
    disp_l(lines(l));
end

% Check lines inside Motor_System
disp('=== Lines in Motor_System ===');
lines2 = get_param([mtpa_blk '/Motor_System'], 'Lines');
for l = 1:length(lines2)
    disp_l(lines2(l));
end

function disp_l(l)
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
            disp_l(l.Branch(b));
        end
    end
end
