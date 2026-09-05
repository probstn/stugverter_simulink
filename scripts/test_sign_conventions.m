% test_sign_conventions.m
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

% Check Subtract and Subtract1 in foc_controller
sub1 = 'foc_controller/Subtract';
sub2 = 'foc_controller/Subtract1';
fprintf('Subtract (Id) Inputs: %s\n', get_param(sub1, 'Inputs'));
fprintf('Subtract1 (Iq) Inputs: %s\n', get_param(sub2, 'Inputs'));

% Check port connectivity of Subtract (Id)
c1 = get_param(sub1, 'PortConnectivity');
for i = 1:length(c1)
    if ~isempty(c1(i).SrcBlock)
        fprintf('  Subtract input %d from %s (port %d)\n', i, get_param(c1(i).SrcBlock, 'Name'), c1(i).SrcPort+1);
    end
end

% Check port connectivity of Subtract1 (Iq)
c2 = get_param(sub2, 'PortConnectivity');
for i = 1:length(c2)
    if ~isempty(c2(i).SrcBlock)
        fprintf('  Subtract1 input %d from %s (port %d)\n', i, get_param(c2(i).SrcBlock, 'Name'), c2(i).SrcPort+1);
    end
end

% Check Demux and Clarke transform connectivity
dm = 'foc_controller/Demux';
ct = 'foc_controller/Clarke Transform';
c_dm = get_param(dm, 'PortConnectivity');
for i = 1:length(c_dm)
    if ~isempty(c_dm(i).DstBlock)
        for d = 1:length(c_dm(i).DstBlock)
            fprintf('  Demux output %d to %s (port %d)\n', i-1, get_param(c_dm(i).DstBlock(d), 'Name'), c_dm(i).DstPort(d)+1);
        end
    end
end
