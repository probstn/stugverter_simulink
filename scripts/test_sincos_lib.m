% test_sincos_lib.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
sc_blk = 'mcbcontrolslib/SinCos Embedded Optimized';
pt_blk = 'mcbcontrolslib/Park Transform';
ipt_blk = 'mcbcontrolslib/Inverse Park Transform';

fprintf('--- SinCos Embedded Optimized ---\n');
sc_in = get_param(sc_blk, 'PortConnectivity');
disp(get_param(sc_blk, 'Ports'));

fprintf('--- Park Transform ---\n');
disp(get_param(pt_blk, 'Ports'));

fprintf('--- Inverse Park Transform ---\n');
disp(get_param(ipt_blk, 'Ports'));

% Let's look inside SinCos Embedded Optimized
sc_subs = find_system(sc_blk, 'LookUnderMasks', 'all', 'Type', 'Block');
for i = 1:length(sc_subs)
    fprintf('  sc block: %s [%s]\n', sc_subs{i}, get_param(sc_subs{i}, 'BlockType'));
end
