% inspect_current_controllers.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_controller');
load_system('foc_plant');

% Check Id and Iq controller mask / parameters
id_blk = 'foc_controller/Id Controller';
fprintf('--- Id Controller Params ---\n');
dps = get_param(id_blk, 'DialogParameters');
flds = {'Controller', 'TimeDomain', 'SampleTime', 'IntegratorMethod', 'P', 'I', 'UpperSaturationLimit', 'LowerSaturationLimit', 'AntiWindupMode'};
for k = 1:length(flds)
    try
        fprintf('  %s: %s\n', flds{k}, num2str(get_param(id_blk, flds{k})));
    catch
    end
end

% Check Clarke Transform block
clarke_blk = 'foc_controller/Clarke Transform';
fprintf('\n--- Clarke Transform ---\n');
try
    params = get_param(clarke_blk, 'MaskNames');
    for k = 1:length(params)
        fprintf('  %s: %s\n', params{k}, get_param(clarke_blk, params{k}));
    end
catch ME
    disp(ME.message);
end

% Check Park Transform block
park_blk = 'foc_controller/Park Transform';
fprintf('\n--- Park Transform ---\n');
try
    params = get_param(park_blk, 'MaskNames');
    for k = 1:length(params)
        fprintf('  %s: %s\n', params{k}, get_param(park_blk, params{k}));
    end
catch ME
    disp(ME.message);
end

% Check Inverse Park Transform block
inv_park = 'foc_controller/Inverse Park Transform';
fprintf('\n--- Inverse Park Transform ---\n');
try
    params = get_param(inv_park, 'MaskNames');
    for k = 1:length(params)
        fprintf('  %s: %s\n', params{k}, get_param(inv_park, params{k}));
    end
catch ME
    disp(ME.message);
end

% Check Mechanical to Electrical Position block
m2e_blk = 'foc_controller/Mechanical to Electrical Position';
fprintf('\n--- Mech to Elec Pos ---\n');
try
    params = get_param(m2e_blk, 'MaskNames');
    for k = 1:length(params)
        fprintf('  %s: %s\n', params{k}, get_param(m2e_blk, params{k}));
    end
catch ME
    disp(ME.message);
end

% Check Inverter sub-blocks in foc_plant
fprintf('\n--- Average-Value Inverter in foc_plant ---\n');
inv_blks = find_system('foc_plant/Average-Value Inverter', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:length(inv_blks)
    fprintf('  %s [%s]\n', inv_blks{i}, get_param(inv_blks{i}, 'BlockType'));
    if strcmp(get_param(inv_blks{i}, 'BlockType'), 'Gain')
        fprintf('     Gain = %s\n', get_param(inv_blks{i}, 'Gain'));
    end
end
