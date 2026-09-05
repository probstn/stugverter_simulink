% check_names.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('foc_system');
blks = find_system('foc_system', 'SearchDepth', 1);
for i = 1:length(blks)
    fprintf('  %s\n', blks{i});
end
