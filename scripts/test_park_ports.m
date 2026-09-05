% test_park_ports.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
pt_blk = 'mcbcontrolslib/Park Transform';
ipt_blk = 'mcbcontrolslib/Inverse Park Transform';

pt_in = find_system(pt_blk, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'SearchDepth', 2, 'BlockType', 'Inport');
for i = 1:length(pt_in)
    fprintf('Park Inport: %s\n', pt_in{i});
end

ipt_in = find_system(ipt_blk, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'SearchDepth', 2, 'BlockType', 'Inport');
for i = 1:length(ipt_in)
    fprintf('Inverse Park Inport: %s\n', ipt_in{i});
end
