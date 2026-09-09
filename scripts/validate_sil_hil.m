%% validate_sil_hil.m
% End-to-end SIL/HIL regression using physical plant speed.

fprintf('\n================================================================\n');
fprintf(' [VALIDATE] Comparing SIL and AURIX TC387 HIL...\n');
fprintf('================================================================\n');

run('run_simulation.m');
silOut = simOut;
silSpeed = silOut.scope_speed{1}.Values;

run('run_hil.m');
hilOut = simOut;
hilSpeed = hilOut.scope_speed{1}.Values;

sampleGrid = (0:foc.Ts:foc.simStopTime).';
silRpm = interp1(silSpeed.Time, silSpeed.Data(:, 2), sampleGrid, 'linear');
hilRpm = interp1(hilSpeed.Time, hilSpeed.Data(:, 2), sampleGrid, 'linear');

metrics.speed_rmse_rpm = sqrt(mean((hilRpm - silRpm).^2));
metrics.speed_max_abs_rpm = max(abs(hilRpm - silRpm));
metrics.peak_speed_difference_rpm = max(hilSpeed.Data(:, 2)) - max(silSpeed.Data(:, 2));
metrics.final_speed_difference_rpm = hilSpeed.Data(end, 2) - silSpeed.Data(end, 2);

fprintf('\n---------------- SIL/HIL EQUIVALENCE ---------------------------\n');
fprintf('  Speed RMSE:               %10.3f RPM\n', metrics.speed_rmse_rpm);
fprintf('  Maximum Speed Difference: %10.3f RPM\n', metrics.speed_max_abs_rpm);
fprintf('  Peak Speed Difference:    %10.3f RPM\n', metrics.peak_speed_difference_rpm);
fprintf('  Final Speed Difference:   %10.3f RPM\n', metrics.final_speed_difference_rpm);
fprintf('----------------------------------------------------------------\n');

assert(metrics.speed_rmse_rpm < 10, 'SIL/HIL speed RMSE exceeds 10 RPM.');
assert(metrics.speed_max_abs_rpm < 25, 'SIL/HIL maximum speed difference exceeds 25 RPM.');
assert(abs(metrics.final_speed_difference_rpm) < 10, 'SIL/HIL final speed difference exceeds 10 RPM.');
fprintf('>>> SIL/HIL equivalence criteria satisfied. <<<\n\n');
