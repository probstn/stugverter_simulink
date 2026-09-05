% check_lines_and_step.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
lines = get_param('foc_system', 'Lines');
fprintf('Lines in foc_system:\n');
for l = 1:length(lines)
    if lines(l).SrcBlock ~= -1
        src = sprintf('%s/%d', get_param(lines(l).SrcBlock, 'Name'), lines(l).SrcPort);
    else
        src = 'none';
    end
    if lines(l).DstBlock ~= -1
        dst = sprintf('%s/%d', get_param(lines(l).DstBlock, 'Name'), lines(l).DstPort);
        fprintf('  %s -> %s\n', src, dst);
    end
    if isfield(lines(l), 'Branch') && ~isempty(lines(l).Branch)
        for b = 1:length(lines(l).Branch)
            br = lines(l).Branch(b);
            if br.DstBlock ~= -1
                fprintf('    --branch--> %s/%d\n', get_param(br.DstBlock, 'Name'), br.DstPort);
            end
        end
    end
end

% Check Step1 parameters
step_blk = 'foc_system/Step1';
fprintf('Step1 Time=%s, Before=%s, After=%s\n', ...
    get_param(step_blk, 'Time'), get_param(step_blk, 'Before'), get_param(step_blk, 'After'));
