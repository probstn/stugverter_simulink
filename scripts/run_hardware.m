%% run_hardware.m
% Read-only XCP monitoring of the TC387 while connected to the physical motor.
% This model intentionally contains no plant, algorithm copy, or XCP STIM.

simulinkDir = fileparts(fileparts(mfilename('fullpath')));
modelsDir = fullfile(simulinkDir, 'models');
addpath(fullfile(simulinkDir, 'scripts'), modelsDir);
run(fullfile(simulinkDir, 'scripts', 'init.m'));

modelName = 'stugverter_hw';
wait_for_xcp('192.168.0.10', 5555, '192.168.0.100', 15);
load_system(fullfile(modelsDir, [modelName '.slx']));
open_system([modelName '/Hardware Monitor']);

fprintf('Monitoring physical hardware for %.1f s (read-only XCP DAQ)...\n', ...
    foc.simStopTime);
simIn = Simulink.SimulationInput(modelName);
simIn = setModelParameter(simIn, 'StopTime', num2str(foc.simStopTime), ...
    'EnablePacing', 'on', 'PacingRate', '1');
simOut = sim(simIn);
fprintf('[+] Hardware monitoring completed. No XCP STIM was transmitted.\n');
