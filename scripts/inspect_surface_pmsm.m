% inspect_surface_pmsm.m
function inspect_surface_pmsm()
    addpath(genpath(pwd));
    run('init.m');
    load_system('foc_system');
    sub = 'foc_system/MTPA Control Reference/Motor_System/Surface PMSM';
    blks = find_system(sub, 'LookUnderMasks', 'all', 'FollowLinks', 'on');
    for i = 1:length(blks)
        b = blks{i};
        fprintf('%s (%s)\n', b, get_param(b, 'BlockType'));
    end
end
