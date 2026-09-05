% view_mcb_cb.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
fprintf('--- MTPA Block Description ---\n');
disp(get_param('mcbcontrolslib/MTPA Control Reference', 'MaskDescription'));
fprintf('--- MTPA Block Help ---\n');
disp(get_param('mcbcontrolslib/MTPA Control Reference', 'MaskHelp'));
