%% init.m (Root project initialization)
% Adds project folders to MATLAB path and loads motor, controller, and bus objects into base workspace.

rootDir = fileparts(mfilename('fullpath'));
if isempty(rootDir)
    rootDir = pwd;
end

addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));

% Execute master initialization in base workspace
if ~strcmp(pwd, rootDir)
    cd(rootDir);
end

run(fullfile(rootDir, 'scripts', 'init.m'));
