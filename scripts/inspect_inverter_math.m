% inspect_inverter_math.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
inv = 'foc_plant/Average-Value Inverter';

% List all blocks and their exact formulas inside Average-Value Inverter
blks = find_system(inv, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(blks)
    b = blks{i};
    bType = get_param(b, 'BlockType');
    fprintf('%s [%s]\n', b, bType);
    if strcmp(bType, 'Gain')
        fprintf('   Gain = %s\n', get_param(b, 'Gain'));
    elseif strcmp(bType, 'Sum')
        fprintf('   Inputs = %s\n', get_param(b, 'Inputs'));
    elseif strcmp(bType, 'Constant')
        fprintf('   Value = %s\n', get_param(b, 'Value'));
    end
end
