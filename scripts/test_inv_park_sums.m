% test_inv_park_sums.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('mcbcontrolslib');
ipt = 'mcbcontrolslib/Inverse Park Transform/Variant/mcb/Inverse Park Transform/Select/Two Inputs/Two inputs CRL';

fprintf('sum_alpha inputs: %s\n', get_param([ipt '/sum_alpha'], 'Inputs'));
fprintf('sum_beta inputs: %s\n', get_param([ipt '/sum_beta'], 'Inputs'));

% Also check what connects to sum_alpha and sum_beta
lines = get_param(ipt, 'Lines');
for l = 1:length(lines)
    if lines(l).SrcBlock ~= -1
        src = get_param(lines(l).SrcBlock, 'Name');
        dst = get_param(lines(l).DstBlock, 'Name');
        fprintf('  %s -> %s\n', src, dst);
    end
end
