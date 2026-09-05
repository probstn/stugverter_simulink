% deep_dive.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

fprintf('================ ALL MODELS AND SUB-BLOCKS ================\n');
models = {'foc_system', 'foc_controller', 'foc_plant', 'foc_speedcontroller'};

for m = 1:length(models)
    mdl = models{m};
    load_system(mdl);
    fprintf('\n----------------- %s -----------------\n', mdl);
    blks = find_system(mdl, 'SearchDepth', 1, 'Type', 'Block');
    for i = 1:length(blks)
        b = blks{i};
        if strcmp(b, mdl), continue; end
        fprintf('Block: %s [%s]\n', get_param(b, 'Name'), get_param(b, 'BlockType'));
        if strcmp(get_param(b, 'BlockType'), 'ModelReference')
            fprintf('   ModelName: %s\n', get_param(b, 'ModelName'));
        end
        if strcmp(get_param(b, 'BlockType'), 'Gain')
            fprintf('   Gain: %s\n', get_param(b, 'Gain'));
        end
        if strcmp(get_param(b, 'BlockType'), 'Step')
            fprintf('   Time: %s, Before: %s, After: %s\n', get_param(b, 'Time'), get_param(b, 'Before'), get_param(b, 'After'));
        end
    end
    
    % Print all line connections
    fprintf('Lines in %s:\n', mdl);
    lines = get_param(mdl, 'Lines');
    for l = 1:length(lines)
        print_line_detail(lines(l));
    end
end

function print_line_detail(line)
    srcBlk = line.SrcBlock;
    srcPort = line.SrcPort;
    if srcBlk ~= -1
        srcStr = sprintf('%s/%d', get_param(srcBlk, 'Name'), srcPort);
    else
        srcStr = 'unconnected';
    end
    
    dstBlk = line.DstBlock;
    dstPort = line.DstPort;
    if dstBlk ~= -1
        dstStr = sprintf('%s/%d', get_param(dstBlk, 'Name'), dstPort);
        fprintf('   %s --> %s\n', srcStr, dstStr);
    end
    
    if isfield(line, 'Branch') && ~isempty(line.Branch)
        for b = 1:length(line.Branch)
            print_branch(line.Branch(b), srcStr);
        end
    end
end

function print_branch(branch, srcStr)
    dstBlk = branch.DstBlock;
    dstPort = branch.DstPort;
    if dstBlk ~= -1
        dstStr = sprintf('%s/%d', get_param(dstBlk, 'Name'), dstPort);
        fprintf('   %s --> %s\n', srcStr, dstStr);
    end
    if isfield(branch, 'Branch') && ~isempty(branch.Branch)
        for b = 1:length(branch.Branch)
            print_branch(branch.Branch(b), srcStr);
        end
    end
end
