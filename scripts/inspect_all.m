% inspect_all.m
projectRoot = fileparts(fileparts(mfilename('fullpath')));
if isempty(projectRoot)
    projectRoot = pwd;
end
cd(projectRoot);
addpath(genpath(projectRoot));

disp('=== Running motor.m and controller.m ===');
run('scripts/motor.m');
run('scripts/controller.m');

disp('Motor struct:');
disp(pmsm);
disp('FOC struct:');
disp(foc);
disp('Kt:');
disp(Kt);
disp('lambda_pm:');
disp(lambda_pm);

disp('=== Loading models ===');
models = {'foc_system', 'foc_controller', 'foc_plant', 'foc_speedcontroller'};
for m = 1:length(models)
    mdl = models{m};
    try
        load_system(mdl);
        fprintf('Loaded model: %s\n', mdl);
        
        % List all blocks in mdl
        blks = find_system(mdl);
        fprintf('Total blocks in %s: %d\n', mdl, length(blks));
        for b = 1:length(blks)
            blkType = get_param(blks{b}, 'BlockType');
            blkName = blks{b};
            fprintf('  [%s] %s\n', blkType, blkName);
        end
    catch ME
        fprintf('Failed to load %s: %s\n', mdl, ME.message);
    end
end
