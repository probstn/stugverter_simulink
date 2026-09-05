% inspect_sincos_connections.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_controller');

% Check SinCos block outports
sincos_blk = 'foc_controller/SinCos Embedded Optimized';
sc_out = find_system(sincos_blk, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Outport');
fprintf('SinCos Outports:\n');
for i = 1:length(sc_out)
    fprintf('  Outport %d: %s\n', i, get_param(sc_out{i}, 'Name'));
end

% Check Park Transform inports
park_blk = 'foc_controller/Park Transform';
fprintf('\nPark Transform inport names:\n');
p_in = find_system(park_blk, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Inport');
for i = 1:length(p_in)
    fprintf('  Inport %d: %s\n', i, get_param(p_in{i}, 'Name'));
end

% Check Inverse Park Transform inports
invp_blk = 'foc_controller/Inverse Park Transform';
fprintf('\nInverse Park Transform inport names:\n');
ip_in = find_system(invp_blk, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Inport');
for i = 1:length(ip_in)
    fprintf('  Inport %d: %s\n', i, get_param(ip_in{i}, 'Name'));
end

% Let's see all port connectivity in foc_controller
port_conns = get_param(sincos_blk, 'PortConnectivity');
disp('SinCos PortConnectivity:');
for i = 1:length(port_conns)
    fprintf('  Port %s (type %s) connects to:\n', port_conns(i).Type, port_conns(i).Position);
    dstB = port_conns(i).DstBlock;
    dstP = port_conns(i).DstPort;
    if ~isempty(dstB)
        for d = 1:length(dstB)
            fprintf('    -> %s (port %d)\n', get_param(dstB(d), 'Name'), dstP(d)+1);
        end
    end
end
