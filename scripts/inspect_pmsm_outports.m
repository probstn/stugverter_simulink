% inspect_pmsm_outports.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_plant');
pmsm_blk = 'foc_plant/Interior PMSM';

% Find Outport blocks inside Interior PMSM
out_blks = find_system(pmsm_blk, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'Outport');
for i = 1:length(out_blks)
    fprintf('Outport %d of Interior PMSM: %s (Port %s)\n', ...
        i, get_param(out_blks{i}, 'Name'), get_param(out_blks{i}, 'Port'));
end

% Also check Bus Selector inside foc_plant
bs_blk = 'foc_plant/Bus Selector';
fprintf('\nBus Selector signals:\n');
fprintf('  OutputSignals: %s\n', get_param(bs_blk, 'OutputSignals'));
