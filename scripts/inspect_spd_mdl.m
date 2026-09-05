% inspect_spd_mdl.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir), rootDir = pwd; end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_speedcontroller');
blks = find_system('foc_speedcontroller', 'Type', 'Block');
fprintf('Blocks in foc_speedcontroller:\n');
for i = 1:length(blks)
    fprintf('  %s [%s]\n', blks{i}, get_param(blks{i}, 'BlockType'));
end

lines = get_param('foc_speedcontroller', 'Lines');
fprintf('Lines in foc_speedcontroller:\n');
for l = 1:length(lines)
    if lines(l).SrcBlock ~= -1
        src = sprintf('%s/%d', get_param(lines(l).SrcBlock, 'Name'), lines(l).SrcPort);
    else
        src = 'none';
    end
    if lines(l).DstBlock ~= -1
        dst = sprintf('%s/%d', get_param(lines(l).DstBlock, 'Name'), lines(l).DstPort);
        fprintf('  %s -> %s\n', src, dst);
    end
end

% Check PI Controller parameters in foc_speedcontroller
pi_blk = 'foc_speedcontroller/PI Controller';
fprintf('PI Controller parameters in foc_speedcontroller:\n');
fprintf('  Controller = %s\n', get_param(pi_blk, 'Controller'));
fprintf('  P = %s\n', get_param(pi_blk, 'P'));
fprintf('  I = %s\n', get_param(pi_blk, 'I'));
fprintf('  UpperSaturationLimit = %s\n', get_param(pi_blk, 'UpperSaturationLimit'));
fprintf('  LowerSaturationLimit = %s\n', get_param(pi_blk, 'LowerSaturationLimit'));
fprintf('  TimeDomain = %s\n', get_param(pi_blk, 'TimeDomain'));
fprintf('  SampleTime = %s\n', get_param(pi_blk, 'SampleTime'));
