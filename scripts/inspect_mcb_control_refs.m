% inspect_mcb_control_refs.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
vcr = 'mcbcontrolslib/Vector Control Reference';
mask_params = get_param(vcr, 'MaskNames');
fprintf('Vector Control Reference mask parameters:\n');
for i = 1:length(mask_params)
    fprintf('  %s\n', mask_params{i});
end
