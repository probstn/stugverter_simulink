% inspect_mtpa_lib.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
mtpa_lib_blk = 'mcbcontrolslib/MTPA Control Reference';
disp('Mask type:');
disp(get_param(mtpa_lib_blk, 'MaskType'));

% Get popup options for VariantSelect
mask_objs = get_param(mtpa_lib_blk, 'MaskObject');
if ~isempty(mask_objs)
    params = mask_objs.Parameters;
    for i = 1:length(params)
        fprintf('Param: %s, Prompt: %s, Type: %s\n', params(i).Name, params(i).Prompt, params(i).Type);
        if strcmp(params(i).Type, 'popup') || strcmp(params(i).Type, 'radiobutton')
            fprintf('   Options: %s\n', strjoin(params(i).TypeOptions, ', '));
        end
    end
end
