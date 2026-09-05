%% inspect_we_connection.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');

sys = 'foc_system/MTPA Control Reference/Motor_System/Interior PMSM';
inports = find_system(sys, 'SearchDepth', 1, 'BlockType', 'Inport');
for i = 1:length(inports)
    fprintf('Inport: %s (Port %s)\n', inports{i}, get_param(inports{i}, 'Port'));
end

lines = get_param(sys, 'Lines');
for i = 1:length(lines)
    fprintf('Line Src: %d, Dst: %d\n', lines(i).SrcBlock, lines(i).DstBlock);
end
