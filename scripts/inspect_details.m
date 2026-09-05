% inspect_details.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

run('init.m');

fprintf('\n================== foc_system BLOCKS & PARAMS ==================\n');
load_system('foc_system');
blks = find_system('foc_system', 'SearchDepth', 1, 'Type', 'Block');
for i = 1:length(blks)
    b = blks{i};
    if strcmp(b, 'foc_system'), continue; end
    fprintf('Block: %s (%s)\n', get_param(b, 'Name'), get_param(b, 'BlockType'));
    params = get_param(b, 'DialogParameters');
    if ~isempty(params)
        f = fieldnames(params);
        for j = 1:length(f)
            p = f{j};
            try
                val = get_param(b, p);
                fprintf('   %s = %s\n', p, num2str(val));
            catch
            end
        end
    end
end

fprintf('\n================== foc_plant BLOCKS & PARAMS ==================\n');
load_system('foc_plant');
blks = find_system('foc_plant', 'SearchDepth', 1, 'Type', 'Block');
for i = 1:length(blks)
    b = blks{i};
    if strcmp(b, 'foc_plant'), continue; end
    fprintf('Block: %s (%s)\n', get_param(b, 'Name'), get_param(b, 'BlockType'));
    params = get_param(b, 'DialogParameters');
    if ~isempty(params)
        f = fieldnames(params);
        for j = 1:length(f)
            p = f{j};
            try
                val = get_param(b, p);
                fprintf('   %s = %s\n', p, num2str(val));
            catch
            end
        end
    end
end

fprintf('\n================== foc_controller BLOCKS & PARAMS ==================\n');
load_system('foc_controller');
blks = find_system('foc_controller', 'SearchDepth', 1, 'Type', 'Block');
for i = 1:length(blks)
    b = blks{i};
    if strcmp(b, 'foc_controller'), continue; end
    fprintf('Block: %s (%s)\n', get_param(b, 'Name'), get_param(b, 'BlockType'));
    params = get_param(b, 'DialogParameters');
    if ~isempty(params)
        f = fieldnames(params);
        for j = 1:length(f)
            p = f{j};
            try
                val = get_param(b, p);
                fprintf('   %s = %s\n', p, num2str(val));
            catch
            end
        end
    end
end

fprintf('\n================== foc_speedcontroller BLOCKS & PARAMS ==================\n');
load_system('foc_speedcontroller');
blks = find_system('foc_speedcontroller', 'SearchDepth', 1, 'Type', 'Block');
for i = 1:length(blks)
    b = blks{i};
    if strcmp(b, 'foc_speedcontroller'), continue; end
    fprintf('Block: %s (%s)\n', get_param(b, 'Name'), get_param(b, 'BlockType'));
    params = get_param(b, 'DialogParameters');
    if ~isempty(params)
        f = fieldnames(params);
        for j = 1:length(f)
            p = f{j};
            try
                val = get_param(b, p);
                fprintf('   %s = %s\n', p, num2str(val));
            catch
            end
        end
    end
end
