% test_signal_labels.m
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
for l = 1:length(lines)
    sigName = get_param(lines(l).Handle, 'Name');
    srcB = lines(l).SrcBlock;
    if srcB ~= -1
        srcName = get_param(srcB, 'Name');
        fprintf('Line from %s (port %d): Name="%s", DataLogging=%s\n', ...
            srcName, lines(l).SrcPort, sigName, get_param(lines(l).Handle, 'DataLogging'));
    end
end
