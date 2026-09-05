% inspect_models.m
addpath('scripts');
addpath('models');
try
    run('init.m');
    disp('Init successful. Checking models...');
    load_system('foc_system');
    load_system('foc_controller');
    load_system('foc_plant');
    load_system('foc_speedcontroller');
    
    disp('--- foc_system blocks ---');
    blks = find_system('foc_system', 'SearchDepth', 1);
    for i = 1:length(blks)
        disp(['  ' blks{i}]);
    end
    
    disp('--- foc_controller blocks ---');
    blks_c = find_system('foc_controller', 'SearchDepth', 1);
    for i = 1:length(blks_c)
        disp(['  ' blks_c{i}]);
    end

    disp('--- foc_plant blocks ---');
    blks_p = find_system('foc_plant', 'SearchDepth', 1);
    for i = 1:length(blks_p)
        disp(['  ' blks_p{i}]);
    end

    disp('--- foc_speedcontroller blocks ---');
    blks_s = find_system('foc_speedcontroller', 'SearchDepth', 1);
    for i = 1:length(blks_s)
        disp(['  ' blks_s{i}]);
    end

    disp('--- Attempting simulation ---');
    set_param('foc_system', 'StopTime', '0.05');
    simOut = sim('foc_system');
    disp('Simulation finished successfully!');
catch ME
    disp('Error caught:');
    disp(ME.message);
    if ~isempty(ME.cause)
        disp('Causes:');
        for c = 1:length(ME.cause)
            disp(ME.cause{c}.message);
        end
    end
    for k = 1:length(ME.stack)
        disp(ME.stack(k));
    end
end
