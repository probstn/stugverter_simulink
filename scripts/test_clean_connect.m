% test_clean_connect.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
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
        src = 'unconnected';
    end
    if lines(l).DstBlock ~= -1
        dst = sprintf('%s/%d', get_param(lines(l).DstBlock, 'Name'), lines(l).DstPort);
        fprintf('  %s -> %s\n', src, dst);
    end
end
