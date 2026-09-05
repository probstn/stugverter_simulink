%% inspect_foc_controller_blocks.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_controller');

% Check Mechanical to Electrical Position
m2e_blks = find_system('foc_controller/Mechanical to Electrical Position', 'LookUnderMasks', 'all');
for i = 1:length(m2e_blks)
    fprintf('M2E [%d]: %s (%s)\n', i, m2e_blks{i}, get_param(m2e_blks{i}, 'BlockType'));
    if strcmp(get_param(m2e_blks{i}, 'BlockType'), 'Gain')
        fprintf('   Gain: %s\n', get_param(m2e_blks{i}, 'Gain'));
    end
end

% Check SinCos Embedded Optimized
sincos_blks = find_system('foc_controller/SinCos Embedded Optimized', 'LookUnderMasks', 'all');
for i = 1:length(sincos_blks)
    fprintf('SinCos [%d]: %s (%s)\n', i, sincos_blks{i}, get_param(sincos_blks{i}, 'BlockType'));
end
