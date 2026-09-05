% inspect_mtpa_block.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
mtpa_blk = 'foc_system/MTPA Control Reference';

% Find sub-blocks in MTPA Control Reference
disp('--- MTPA Block Type / Mask ---');
disp(get_param(mtpa_blk, 'MaskType'));
disp('--- Mask Dialog Parameters ---');
mask_prompts = get_param(mtpa_blk, 'MaskPrompts');
mask_names = get_param(mtpa_blk, 'MaskNames');
mask_values = get_param(mtpa_blk, 'MaskValues');
for k = 1:length(mask_names)
    fprintf('%s (%s): %s\n', mask_names{k}, mask_prompts{k}, mask_values{k});
end

% Check if it has internal blocks or library reference
disp('--- SourceBlock / Reference ---');
try
    disp(get_param(mtpa_blk, 'ReferenceBlock'));
catch
end
try
    disp(get_param(mtpa_blk, 'AncestorBlock'));
catch
end

% List children of MTPA block
children = find_system(mtpa_blk, 'SearchDepth', 2);
disp('--- Children of MTPA block ---');
disp(children);
