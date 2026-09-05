% test_sim.m
try
    rootDir = fileparts(fileparts(mfilename('fullpath')));
    if isempty(rootDir)
        rootDir = pwd;
    end
    addpath(fullfile(rootDir, 'scripts'));
    addpath(fullfile(rootDir, 'models'));
    cd(rootDir);

    run('init.m');
    
    models = {'foc_system', 'foc_controller', 'foc_plant', 'foc_speedcontroller'};
    for m = 1:length(models)
        mdl = models{m};
        load_system(mdl);
        fprintf('Successfully loaded %s\n', mdl);
    end

    % List all blocks in foc_system
    blks = find_system('foc_system', 'Type', 'Block');
    fprintf('\nBlocks in foc_system:\n');
    for i = 1:length(blks)
        fprintf('  %s (BlockType: %s)\n', blks{i}, get_param(blks{i}, 'BlockType'));
    end

    fprintf('\nSimulating foc_system for 0.01 s...\n');
    set_param('foc_system', 'StopTime', '0.01');
    out = sim('foc_system');
    fprintf('Simulation SUCCESSFUL!\n');
catch ME
    fprintf('Simulation FAILED:\n%s\n', ME.message);
    if ~isempty(ME.cause)
        for c = 1:length(ME.cause)
            fprintf('  Cause %d: %s\n', c, ME.cause{c}.message);
        end
    end
end
