% view_error_cause.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
try
    run('test_speed_filtering.m');
catch ME
    fprintf('Top Error: %s\n', ME.message);
    if ~isempty(ME.cause)
        for i = 1:length(ME.cause)
            fprintf('  Cause %d: %s\n', i, ME.cause{i}.message);
        end
    end
end
