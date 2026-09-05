%% run_powertrain_smoke.m
% Repeatable smoke test for the top-level FOC + MTPA + field-weakening model.

clearvars;
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
run(fullfile(scriptDir, 'init.m'));

simOut = sim('powertrain');
logs = simOut.logsout;

names = { ...
    'spd_ref_rpm', ...
    'spd_meas_rads', ...
    'id_ref', ...
    'id_ref_effective', ...
    'id_actual', ...
    'iq_ref', ...
    'iq_actual', ...
    'Vd_cmd', ...
    'Vq_cmd' ...
};

fprintf('\nFOC smoke test summary\n');
fprintf('Stop time: %.3f s\n', foc.simStopTime);
fprintf('Current-loop bandwidth: %.0f Hz\n', foc.current_bw_hz);
fprintf('Speed-loop bandwidth: %.0f Hz\n', foc.speed_bw_hz);
fprintf('Voltage phase limit used for FW: %.1f V\n\n', foc.V_phase_max);

for k = 1:numel(names)
    sig = logs.get(names{k});
    if isempty(sig)
        continue;
    end

    data = sig.Values.Data;
    fprintf('%-17s final=%10.4g min=%10.4g max=%10.4g\n', ...
        names{k}, data(end), min(data(:)), max(data(:)));
end

spd = logs.get('spd_meas_rads').Values.Data * 30/pi;
fprintf('\nMeasured speed: final=%.1f rpm, max=%.1f rpm\n', spd(end), max(spd));
