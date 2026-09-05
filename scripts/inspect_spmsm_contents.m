% inspect_spmsm_contents.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('mcbcontrolslib');
mtpa_lib = 'mcbcontrolslib/MTPA Control Reference';

% Look inside Motor_System/Surface PMSM and Interior PMSM
fprintf('=== Surface PMSM subsystem in library ===\n');
spmsm_blks = find_system([mtpa_lib '/Motor_System/Surface PMSM'], 'SearchDepth', 2, 'Type', 'Block');
for i = 1:length(spmsm_blks)
    fprintf('  %s [%s]\n', spmsm_blks{i}, get_param(spmsm_blks{i}, 'BlockType'));
end

fprintf('\n=== Interior PMSM subsystem in library ===\n');
ipmsm_blks = find_system([mtpa_lib '/Motor_System/Interior PMSM'], 'SearchDepth', 2, 'Type', 'Block');
for i = 1:length(ipmsm_blks)
    fprintf('  %s [%s]\n', ipmsm_blks{i}, get_param(ipmsm_blks{i}, 'BlockType'));
end
