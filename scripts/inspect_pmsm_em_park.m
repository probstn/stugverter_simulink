% inspect_pmsm_em_park.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
pt = 'foc_plant/Interior PMSM/PMSM Torque Input Continuous/PMSM Torque Input Core/PMSM Electromagnetic/Park Transform';
lines = get_param(pt, 'Lines');
fprintf('Lines in PMSM Electromagnetic Park Transform:\n');
for l = 1:length(lines)
    if lines(l).SrcBlock ~= -1 && lines(l).DstBlock ~= -1
        src = get_param(lines(l).SrcBlock, 'Name');
        dst = get_param(lines(l).DstBlock, 'Name');
        fprintf('  %s -> %s\n', src, dst);
    end
end
