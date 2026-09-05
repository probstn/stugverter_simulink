% test_spmsm_cb.m
function test_spmsm_cb()
    addpath('scripts');
    addpath('models');
    run('init.m');
    
    load_system('foc_system');
    blk = 'foc_system/MTPA Control Reference';
    
    % Set to Surface PMSM and SI Units
    set_param(blk, 'VariantSelect', 'Surface PMSM');
    set_param(blk, 'Units', 'SI Units');
    set_param(blk, 'polePairs', 'pmsm.P');
    set_param(blk, 'Rs', 'pmsm.Rs');
    set_param(blk, 'Ld', 'pmsm.Lph');
    set_param(blk, 'Lq', 'pmsm.Lph');
    set_param(blk, 'FluxPM', 'pmsm.fl');
    set_param(blk, 'ilimit', 'pmsm.I_rated');
    set_param(blk, 'V_dc', 'pmsm.V_rated');
    
    % Call callback
    mtpablkSett = mcb.internal.PMSMRefCurrentGeneratorCb(get_param(blk, 'Handle'));
    fprintf('=== mtpablkSett for Surface PMSM (SI Units) ===\n');
    disp(mtpablkSett);
end
