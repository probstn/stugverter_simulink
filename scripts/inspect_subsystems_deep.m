%% inspect_subsystems_deep.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_controller');

m2e = find_system('foc_controller/Mechanical to Electrical Position', 'LookUnderMasks', 'all', 'FollowLinks', 'on');
for i = 1:length(m2e)
    fprintf('M2E: %s (%s)\n', m2e{i}, get_param(m2e{i}, 'BlockType'));
    if strcmp(get_param(m2e{i}, 'BlockType'), 'Gain')
        fprintf('  Gain: %s\n', get_param(m2e{i}, 'Gain'));
    end
end

sincos = find_system('foc_controller/SinCos Embedded Optimized', 'LookUnderMasks', 'all', 'FollowLinks', 'on');
for i = 1:length(sincos)
    fprintf('SinCos: %s (%s)\n', sincos{i}, get_param(sincos{i}, 'BlockType'));
    if strcmp(get_param(sincos{i}, 'BlockType'), 'Trigonometry')
        fprintf('  Operator: %s\n', get_param(sincos{i}, 'Operator'));
    end
end
