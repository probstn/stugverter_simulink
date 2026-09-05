% inspect_blocks_tree.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

fprintf('================ MTPA Control Reference Mask Params ================\n');
load_system('foc_system');
mtpa_blk = 'foc_system/MTPA Control Reference';
try
    mask_names = get_param(mtpa_blk, 'MaskNames');
    for k = 1:length(mask_names)
        fprintf('  %s = %s\n', mask_names{k}, get_param(mtpa_blk, mask_names{k}));
    end
catch ME
    fprintf('Error reading mask: %s\n', ME.message);
end

fprintf('\n================ foc_system Ports and Connections ================\n');
lines = get_param('foc_system', 'Lines');
for l = 1:length(lines)
    describe_line(lines(l), '');
end

fprintf('\n================ foc_plant Interior PMSM Mask Params ================\n');
load_system('foc_plant');
pmsm_blk = 'foc_plant/Interior PMSM';
try
    mask_names = get_param(pmsm_blk, 'MaskNames');
    for k = 1:length(mask_names)
        fprintf('  %s = %s\n', mask_names{k}, get_param(pmsm_blk, mask_names{k}));
    end
catch ME
    fprintf('Error reading mask: %s\n', ME.message);
end

fprintf('\n================ foc_plant Inverter Params ================\n');
inv_blk = 'foc_plant/Average-Value Inverter';
try
    mask_names = get_param(inv_blk, 'MaskNames');
    for k = 1:length(mask_names)
        fprintf('  %s = %s\n', mask_names{k}, get_param(inv_blk, mask_names{k}));
    end
catch ME
    fprintf('Error reading mask: %s\n', ME.message);
end

fprintf('\n================ foc_controller Id & Iq PI params ================\n');
load_system('foc_controller');
id_pi = 'foc_controller/Id Controller';
fprintf('Id PI: P=%s, I=%s, UpperSat=%s, LowerSat=%s\n', ...
    get_param(id_pi, 'P'), get_param(id_pi, 'I'), ...
    get_param(id_pi, 'UpperSaturationLimit'), get_param(id_pi, 'LowerSaturationLimit'));
iq_pi = 'foc_controller/Iq Controller';
fprintf('Iq PI: P=%s, I=%s, UpperSat=%s, LowerSat=%s\n', ...
    get_param(iq_pi, 'P'), get_param(iq_pi, 'I'), ...
    get_param(iq_pi, 'UpperSaturationLimit'), get_param(iq_pi, 'LowerSaturationLimit'));

fprintf('\n================ foc_controller PWM Ref Gen / Inverter scaling ================\n');
pwm_blk = 'foc_controller/PWM Reference Generator';
try
    mask_names = get_param(pwm_blk, 'MaskNames');
    for k = 1:length(mask_names)
        fprintf('  %s = %s\n', mask_names{k}, get_param(pwm_blk, mask_names{k}));
    end
catch ME
    fprintf('PWM Ref Gen error: %s\n', ME.message);
end

fprintf('\n================ foc_speedcontroller PI params ================\n');
load_system('foc_speedcontroller');
spd_pi = 'foc_speedcontroller/PI Controller';
fprintf('Speed PI: P=%s, I=%s, UpperSat=%s, LowerSat=%s\n', ...
    get_param(spd_pi, 'P'), get_param(spd_pi, 'I'), ...
    get_param(spd_pi, 'UpperSaturationLimit'), get_param(spd_pi, 'LowerSaturationLimit'));


function describe_line(lineStruct, prefix)
    srcBlk = lineStruct.SrcBlock;
    srcPort = lineStruct.SrcPort;
    if srcBlk ~= -1
        srcStr = sprintf('%s (port %s)', get_param(srcBlk, 'Name'), srcPort);
    else
        srcStr = 'none';
    end
    
    dstBlk = lineStruct.DstBlock;
    dstPort = lineStruct.DstPort;
    if dstBlk ~= -1
        dstStr = sprintf('%s (port %s)', get_param(dstBlk, 'Name'), dstPort);
        fprintf('%s%s  --->  %s\n', prefix, srcStr, dstStr);
    end
    
    if isfield(lineStruct, 'Branch') && ~isempty(lineStruct.Branch)
        for b = 1:length(lineStruct.Branch)
            describe_line(lineStruct.Branch(b), [prefix '  --branch--> ']);
        end
    end
end
