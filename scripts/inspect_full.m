% inspect_full.m
function inspect_full()
    rootDir = fileparts(fileparts(mfilename('fullpath')));
    if isempty(rootDir)
        rootDir = pwd;
    end
    addpath(fullfile(rootDir, 'scripts'));
    addpath(fullfile(rootDir, 'models'));
    cd(rootDir);
    
    % Let's first inspect init.m, motor.m, controller.m variables
    run('motor.m');
    run('controller.m');
    
    models = {'foc_system', 'foc_controller', 'foc_plant', 'foc_speedcontroller'};
    for m = 1:length(models)
        mdl = models{m};
        fprintf('\n=======================================================\n');
        fprintf('MODEL: %s\n', mdl);
        fprintf('=======================================================\n');
        load_system(mdl);
        
        blks = find_system(mdl, 'Type', 'Block');
        fprintf('Found %d blocks:\n', length(blks));
        for b = 1:length(blks)
            blk = blks{b};
            bType = get_param(blk, 'BlockType');
            fprintf('  - %s [%s]\n', blk, bType);
            if strcmp(bType, 'Reference')
                fprintf('      SourceBlock: %s\n', get_param(blk, 'SourceBlock'));
                % Print dialog parameters
                dps = get_param(blk, 'DialogParameters');
                if ~isempty(dps)
                    flds = fieldnames(dps);
                    for f = 1:min(length(flds), 10)
                        fn = flds{f};
                        try
                            val = get_param(blk, fn);
                            if ischar(val) || isnumeric(val)
                                fprintf('        %s: %s\n', fn, mat2str(val));
                            end
                        catch
                        end
                    end
                end
            elseif strcmp(bType, 'SubSystem')
                maskType = get_param(blk, 'MaskType');
                if ~isempty(maskType)
                    fprintf('      MaskType: %s\n', maskType);
                end
            elseif strcmp(bType, 'MATLABFunction') || strcmp(bType, 'Stateflow')
                fprintf('      MATLAB Function / Stateflow block\n');
            end
        end
    end
    
    % Check ports and connections of foc_system
    fprintf('\n=======================================================\n');
    fprintf('CONNECTIONS IN foc_system\n');
    fprintf('=======================================================\n');
    lines = get_param('foc_system', 'Lines');
    for l = 1:length(lines)
        print_line(lines(l), '  ');
    end
    
    % Try running simulation and capture all diagnostics
    fprintf('\n=======================================================\n');
    fprintf('TESTING SIMULATION OF foc_system\n');
    fprintf('=======================================================\n');
    try
        set_param('foc_system', 'StopTime', '0.05');
        out = sim('foc_system');
        fprintf('SUCCESS: Simulation ran without error!\n');
    catch ME
        fprintf('ERROR during simulation: %s\n', ME.message);
        report_me(ME, '  ');
    end
end

function print_line(lineStruct, indent)
    srcBlk = lineStruct.SrcBlock;
    if srcBlk ~= -1
        srcName = get_param(srcBlk, 'Name');
        srcPort = lineStruct.SrcPort;
    else
        srcName = 'none';
        srcPort = -1;
    end
    
    dstBlk = lineStruct.DstBlock;
    if dstBlk ~= -1
        dstName = get_param(dstBlk, 'Name');
        dstPort = lineStruct.DstPort;
        fprintf('%s%s:%d -> %s:%d\n', indent, srcName, srcPort, dstName, dstPort);
    end
    
    if isfield(lineStruct, 'Branch') && ~isempty(lineStruct.Branch)
        for b = 1:length(lineStruct.Branch)
            print_line(lineStruct.Branch(b), [indent '  [branch] ']);
        end
    end
end

function report_me(ME, indent)
    if ~isempty(ME.cause)
        for c = 1:length(ME.cause)
            fprintf('%sCause: %s\n', indent, ME.cause{c}.message);
            report_me(ME.cause{c}, [indent '  ']);
        end
    end
end
