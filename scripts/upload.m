%% upload.m
% Automates building the AURIX project in Eclipse headless mode and flashing the target MCU via AURIX Flasher.
%
% Usage:
%   run('upload.m')             % Builds and flashes
%   or in MATLAB Command Window:
%   upload                      % (when scripts folder is on MATLAB path)

%% 1. Locate Directories and Project Paths
scriptDir = fileparts(mfilename('fullpath'));
repoRoot  = fullfile(scriptDir, '..', '..');

firmwareDir   = fullfile(repoRoot, 'firmware');
projectName   = 'firmware';
buildConfig   = 'Debug';
hexFile       = fullfile(firmwareDir, buildConfig, [projectName, '.hex']);
workspaceDir  = fullfile(repoRoot, '.workspace_headless');

%% 2. Auto-Detect Toolchain Paths (with fallback to default paths)
% Eclipse & JRE
infineonBase = 'C:\Infineon';

% Locate AURIX-Configuration-Studio / Eclipse
acsDirs = dir(fullfile(infineonBase, 'AURIX-Configuration-Studio-*'));
if ~isempty(acsDirs)
    eclipseDir = fullfile(infineonBase, acsDirs(end).name, 'eclipse');
else
    eclipseDir = 'C:\Infineon\AURIX-Configuration-Studio-1.0.22\eclipse';
end

% Locate Java runtime inside Eclipse plugins
jreDirs = dir(fullfile(eclipseDir, 'plugins', 'org.eclipse.justj.openjdk.hotspot.jre.full.*'));
if ~isempty(jreDirs)
    javaExe = fullfile(eclipseDir, 'plugins', jreDirs(end).name, 'jre', 'bin', 'java.exe');
else
    javaExe = 'java'; % Fallback to system java
end

% Locate Equinox launcher jar
launcherFiles = dir(fullfile(eclipseDir, 'plugins', 'org.eclipse.equinox.launcher_*.jar'));
if ~isempty(launcherFiles)
    launcherJar = fullfile(eclipseDir, 'plugins', launcherFiles(end).name);
else
    error('Eclipse Equinox Launcher JAR not found in: %s', fullfile(eclipseDir, 'plugins'));
end

% Locate AURIX Flasher
flasherDirs = dir(fullfile(infineonBase, 'AURIXFlasherSoftwareTool-*'));
if ~isempty(flasherDirs)
    flasherExe = fullfile(infineonBase, flasherDirs(end).name, 'AURIXFlasher.exe');
else
    flasherExe = 'C:\Infineon\AURIXFlasherSoftwareTool-3.0.18\AURIXFlasher.exe';
end

if ~exist(flasherExe, 'file')
    error('AURIX Flasher executable not found: %s', flasherExe);
end

%% 3. Compile Project in Eclipse Headless Mode
disp('================================================================');
disp(' Step 1: Compiling Firmware (Eclipse Headless Mode - TriCore GCC)');
disp('================================================================');

buildCmd = sprintf('"%s" -jar "%s" -nosplash -verbose -data "%s" -application org.eclipse.cdt.managedbuilder.core.headlessbuild -import "%s" -cleanBuild "%s/%s"', ...
    javaExe, launcherJar, workspaceDir, firmwareDir, projectName, buildConfig);

fprintf('Running command:\n%s\n\n', buildCmd);
tic;
% '-echo' streams stdout/stderr directly to the MATLAB Command Window in real time
[status, cmdout] = system(buildCmd, '-echo');
buildTime = toc;

if status ~= 0 || ~exist(hexFile, 'file')
    error('Firmware compilation failed (exit code %d). Check compiler output above.', status);
else
    fprintf('\nBuild SUCCESSFUL in %.2f seconds.\n', buildTime);
    fprintf('Generated HEX: %s\n\n', hexFile);
end

%% 4. Flash Firmware via AURIX Flasher Tool
disp('================================================================');
disp(' Step 2: Flashing Firmware to AURIX MCU (AURIX Flasher Tool)    ');
disp('================================================================');

flashCmd = sprintf('"%s" -hex "%s"', flasherExe, hexFile);

fprintf('Running command:\n%s\n\n', flashCmd);
tic;
% '-echo' streams stdout/stderr directly to the MATLAB Command Window in real time
[status, cmdout] = system(flashCmd, '-echo');
flashTime = toc;

if status ~= 0
    error('Flashing failed (exit code %d). Check flasher output above.', status);
else
    fprintf('\nFlashing SUCCESSFUL in %.2f seconds.\n\n', flashTime);
end

disp('================================================================');
disp(' Complete: Code built, flashed, and running on target!         ');
disp('================================================================');