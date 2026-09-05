% inspect_plant_details.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
blks = find_system('foc_plant', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for i = 1:min(length(blks), 30)
    fprintf('foc_plant sub-block: %s [%s]\n', blks{i}, get_param(blks{i}, 'BlockType'));
end

% Let's inspect the Interior PMSM block in foc_plant
pmsm_blk = 'foc_plant/Interior PMSM';
fprintf('\n--- Interior PMSM in foc_plant ---\n');
fprintf('SourceBlock: %s\n', get_param(pmsm_blk, 'SourceBlock'));
mask_names = get_param(pmsm_blk, 'MaskNames');
mask_values = get_param(pmsm_blk, 'MaskValues');
for k = 1:length(mask_names)
    fprintf('  %s = %s\n', mask_names{k}, mask_values{k});
end
