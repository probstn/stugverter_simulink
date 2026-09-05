% inspect_spmsm_subsystem.m
function inspect_spmsm_subsystem()
    load_system('mcbcontrolslib');
    blks = find_system('mcbcontrolslib/MTPA Control Reference/Motor_System/Surface Mount PMSM', 'LookUnderMasks', 'all');
    fprintf('Found %d blocks in Surface Mount PMSM subsystem:\n', length(blks));
    for i = 1:length(blks)
        b = blks{i};
        fprintf('  [%s] %s\n', get_param(b, 'BlockType'), b);
    end
end
