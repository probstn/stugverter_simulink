%% stugverter.m
% =========================================================================
% STUGVERTER MASTER AUTOMATION SCRIPT
% =========================================================================
% Modular workflow for the Infineon AURIX TC387 + Fischer IPMSM FOC project.
%
% This script is organized into 5 executable sections:
%   1. Set Up Variables   - Loads motor, controller, bus definitions & speed profile
%   2. Run Simulation     - Executes top-level stugverter.slx model
%   3. Show Results       - Computes metrics, prints validation table, & plots graphs
%   4. Generate Code      - Triggers Embedded Coder build & audits generated C code
%   5. Deploy to Firmware - Copies generated algorithm files to firmware/algorithm
%
% Usage:
%   - Run entire script:   run('stugverter.m')
%   - Run single section:  In MATLAB Editor, place cursor in section and press Ctrl+Enter

%% Section 1: Set Up Variables
fprintf('\n================================================================\n');
fprintf(' [Section 1] Setting up Stugverter FOC Variables & Parameters...\n');
fprintf('================================================================\n');

% 1. Resolve project root directory (robust to MATLAB Editor temp section execution)
rootDir = '';

% Try active editor file (when running a section in the MATLAB Editor)
if isempty(rootDir) && matlab.desktop.editor.isEditorAvailable
    try
        activeDoc = matlab.desktop.editor.getActive;
        if ~isempty(activeDoc) && ~isempty(activeDoc.Filename)
            cand = fileparts(activeDoc.Filename);
            if exist(fullfile(cand, 'scripts', 'motor.m'), 'file')
                rootDir = cand;
            end
        end
    catch
    end
end

% Try which('stugverter.m')
if isempty(rootDir)
    wFile = which('stugverter.m');
    if ~isempty(wFile)
        cand = fileparts(wFile);
        if exist(fullfile(cand, 'scripts', 'motor.m'), 'file')
            rootDir = cand;
        end
    end
end

% Try filesystem candidates relative to current working directory
if isempty(rootDir)
    candidates = {pwd, fullfile(pwd, 'simulink'), fileparts(pwd), ...
                  fullfile(fileparts(pwd), 'simulink'), ...
                  'C:\Users\probst\Desktop\stugverter\simulink'};
    for c = 1:length(candidates)
        if exist(fullfile(candidates{c}, 'scripts', 'motor.m'), 'file')
            rootDir = candidates{c};
            break;
        end
    end
end

% Try mfilename only if NOT running from a temporary editor directory
if isempty(rootDir)
    cand = fileparts(mfilename('fullpath'));
    if ~isempty(cand) && ~contains(lower(cand), 'temp') && exist(fullfile(cand, 'scripts', 'motor.m'), 'file')
        rootDir = cand;
    end
end

if isempty(rootDir) || ~exist(fullfile(rootDir, 'scripts', 'motor.m'), 'file')
    error('Could not locate Stugverter project directory. Please cd to the simulink project folder.');
end

% Canonicalize path
rootDir = char(java.io.File(rootDir).getCanonicalPath());

addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));

% Suppress shadowing warning between stugverter.m and models/stugverter.slx
warning('off', 'Simulink:Engine:MdlFileShadowedByFile');

% 2. Load PMSM parameters (IPMSM with Fischer TI085 motor specs: Ld != Lq)
run(fullfile(rootDir, 'scripts', 'motor.m'));

% 3. Load Controller parameters, timing, EVADC configuration, and bus objects
run(fullfile(rootDir, 'scripts', 'controller.m'));

% 4. Default Multi-Regime Speed Reference Profile (RPM)
%   0 -> 8,000 RPM (MTPA regime)
%   8,000 -> 18,000 RPM (Field weakening regime)
%   18,000 -> 6,000 RPM (Deceleration return to MTPA regime)
foc.simStopTime = 0.80;
t_prof   = [0, 0.05, 0.25, 0.45, 0.60, 0.80];
spd_prof = single([0, 0, 8000, 18000, 18000, 6000]);
sp_ts    = timeseries(spd_prof, t_prof);

% 5. Export variables to base workspace for Simulink evaluation
varList = who;
for k = 1:length(varList)
    assignin('base', varList{k}, eval(varList{k}));
end

fprintf('Parameters and Bus Objects initialized successfully:\n');
fprintf('  Motor:     TI085-052-070-04B7S (4 pole pairs, Ld=%.2f mH, Lq=%.2f mH, Ke=%.3f)\n', ...
    pmsm.Ld*1e3, pmsm.Lq*1e3, pmsm.Ke_data);
fprintf('  Inverter:  V_dc = %.0f V, Phase limit = %.1f V, Sample rate = %.0f kHz\n', ...
    pmsm.V_rated, foc.V_phase_max, (1/foc.Ts)/1e3);
fprintf('  Profile:   Ramp to 18,000 RPM over %.2f s simulation time\n', foc.simStopTime);
fprintf('================================================================\n\n');


%% Section 2: Run Simulation
fprintf('\n================================================================\n');
fprintf(' [Section 2] Running Simulation of stugverter.slx...\n');
fprintf('================================================================\n');

modelName = 'stugverter';
if ~bdIsLoaded(modelName)
    fprintf('Loading model "%s"...\n', modelName);
    load_system(modelName);
end

fprintf('Simulating %s for StopTime = %.2f seconds...\n', modelName, foc.simStopTime);
tic;
simOut = sim(modelName);
simTimeElapsed = toc;
fprintf('Simulation completed in %.2f seconds.\n', simTimeElapsed);
fprintf('================================================================\n\n');


%% Section 3: Show Results
fprintf('\n================================================================\n');
fprintf(' [Section 3] Simulation Results & Performance Metrics\n');
fprintf('================================================================\n');

if ~exist('simOut', 'var')
    error('Simulation output "simOut" not found. Please run Section 2 first.');
end

if ~exist('rootDir', 'var') || isempty(rootDir) || ~exist(fullfile(rootDir, 'scripts', 'motor.m'), 'file')
    wFile = which('stugverter.m');
    if ~isempty(wFile), rootDir = fileparts(wFile); else, rootDir = pwd; end
end

logs = simOut.logsout;

% Safe signal extractor from Dataset
getSignal = @(logsObj, name) (logsObj.get(name).Values);

try
    spd_ref    = getSignal(logs, 'spd_ref_rads');
    spd_meas   = getSignal(logs, 'spd_meas_rads');
    id_ref_eff = getSignal(logs, 'id_ref_effective');
    id_act     = getSignal(logs, 'id_actual');
    iq_ref     = getSignal(logs, 'iq_ref');
    iq_act     = getSignal(logs, 'iq_actual');
    Vd_cmd     = getSignal(logs, 'Vd_cmd');
    Vq_cmd     = getSignal(logs, 'Vq_cmd');
catch ME
    error('Could not extract required logged signals from simOut.logsout: %s', ME.message);
end

% Conversions
t = spd_meas.Time;
rpm_ref  = spd_ref.Data  * (30 / pi);
rpm_meas = spd_meas.Data * (30 / pi);
V_mag    = sqrt(Vd_cmd.Data.^2 + Vq_cmd.Data.^2);

% Key Metrics
max_rpm_ref    = max(rpm_ref);
max_rpm_meas   = max(rpm_meas);
final_rpm_ref  = rpm_ref(end);
final_rpm_meas = rpm_meas(end);
min_id_eff     = min(id_ref_eff.Data);
min_id_act     = min(id_act.Data);
max_id_err     = max(abs(id_act.Data - id_ref_eff.Data));
max_iq_err     = max(abs(iq_act.Data - iq_ref.Data));
max_V_mag      = max(V_mag);

fprintf('------------------- PERFORMANCE SUMMARY --------------------\n');
fprintf('  Max Speed Target:          %10.1f RPM\n', max_rpm_ref);
fprintf('  Max Speed Reached:         %10.1f RPM (Error: %.2f RPM)\n', max_rpm_meas, abs(max_rpm_meas - max_rpm_ref));
fprintf('  Final Speed Target:        %10.1f RPM\n', final_rpm_ref);
fprintf('  Final Speed Reached:       %10.1f RPM (Error: %.2f RPM)\n', final_rpm_meas, abs(final_rpm_meas - final_rpm_ref));
fprintf('  Field Weakening Min Id:    %10.2f A (Target: %.2f A)\n', min_id_act, min_id_eff);
fprintf('  Max Absolute Id Error:     %10.2f A\n', max_id_err);
fprintf('  Max Absolute Iq Error:     %10.2f A\n', max_iq_err);
fprintf('  Peak Stator Phase Voltage: %10.2f V (Phase limit: %.2f V)\n', max_V_mag, foc.V_phase_max);
fprintf('------------------------------------------------------------\n');

% Assertions
assert(max_rpm_meas > 17500, 'Motor failed to reach target speed (> 17500 RPM)');
assert(abs(final_rpm_meas - final_rpm_ref) < 100, 'Final speed tracking error exceeds 100 RPM');
fprintf('>>> All performance criteria satisfied! <<<\n\n');

% Create visualization figure
if feature('ShowFigureWindows')
    figHandle = figure('Name', 'Stugverter FOC Performance', 'NumberTitle', 'off', 'Color', 'w');
else
    figHandle = figure('Name', 'Stugverter FOC Performance', 'NumberTitle', 'off', 'Color', 'w', 'Visible', 'off');
end
set(figHandle, 'Position', [100, 100, 950, 750]);

% Subplot 1: Speed Tracking
subplot(3, 1, 1);
plot(t, rpm_ref, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Reference (RPM)');
hold on;
plot(t, rpm_meas, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Measured (RPM)');
yline(pmsm.N_base, 'r:', 'LineWidth', 1.2, 'DisplayName', 'Base Speed (9,500 RPM)');
grid on;
title('Rotor Mechanical Speed Tracking (MTPA & Field Weakening)');
xlabel('Time [s]');
ylabel('Speed [RPM]');
legend('Location', 'best');

% Subplot 2: dq Currents
subplot(3, 1, 2);
plot(t, id_ref_eff.Data, 'b--', 'LineWidth', 1.2, 'DisplayName', 'i_d Effective Ref');
hold on;
plot(t, id_act.Data, 'b-', 'LineWidth', 1.2, 'DisplayName', 'i_d Actual');
plot(t, iq_ref.Data, 'r--', 'LineWidth', 1.2, 'DisplayName', 'i_q Ref');
plot(t, iq_act.Data, 'r-', 'LineWidth', 1.2, 'DisplayName', 'i_q Actual');
grid on;
title('Stator dq-axis Currents (Demagnetizing i_d & Torque i_q)');
xlabel('Time [s]');
ylabel('Current [A]');
legend('Location', 'best');

% Subplot 3: Phase Voltage Magnitude
subplot(3, 1, 3);
plot(t, V_mag, 'Color', [0.2 0.7 0.2], 'LineWidth', 1.5, 'DisplayName', '|V_{dq}| Commanded');
hold on;
yline(foc.V_phase_max, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{phase,max} Inverter Limit');
grid on;
title('Stator Phase Voltage Magnitude vs. Inverter Saturation Limit');
xlabel('Time [s]');
ylabel('Voltage [V]');
legend('Location', 'best');

% Save plot to images folder
imagesDir = fullfile(rootDir, 'images');
if ~exist(imagesDir, 'dir'), mkdir(imagesDir); end
saveas(figHandle, fullfile(imagesDir, 'stugverter_simulation_results.png'));
fprintf('Results plot saved to: %s\n', fullfile(imagesDir, 'stugverter_simulation_results.png'));


%% Section 4: Generate Code
fprintf('\n================================================================\n');
fprintf(' [Section 4] Generating Embedded C Code from algorithm.slx...\n');
fprintf('================================================================\n');

if ~exist('rootDir', 'var') || isempty(rootDir) || ~exist(fullfile(rootDir, 'scripts', 'motor.m'), 'file')
    wFile = which('stugverter.m');
    if ~isempty(wFile), rootDir = fileparts(wFile); else, rootDir = pwd; end
end

algoModel = 'algorithm';
if ~bdIsLoaded(algoModel)
    fprintf('Loading model "%s"...\n', algoModel);
    load_system(algoModel);
end

fprintf('Building Embedded Coder target for "%s"...\n', algoModel);
tic;
slbuild(algoModel);
buildElapsed = toc;
fprintf('Code generation finished in %.2f seconds.\n', buildElapsed);

codegenDir = fullfile(rootDir, [algoModel, '_ert_rtw']);
if ~exist(codegenDir, 'dir')
    error('Expected code generation directory "%s" not found.', codegenDir);
end

% Audit generated code for single-precision compliance
if exist('audit_algorithm_code', 'file')
    fprintf('Auditing generated C code for single-precision compliance...\n');
    audit_algorithm_code(codegenDir);
end

% List generated artifacts
cFiles = dir(fullfile(codegenDir, '*.c'));
hFiles = dir(fullfile(codegenDir, '*.h'));
fprintf('Generated %d C source and %d header files in:\n  %s\n', ...
    length(cFiles), length(hFiles), codegenDir);
for k = 1:length(cFiles)
    fprintf('  - %s\n', cFiles(k).name);
end
for k = 1:length(hFiles)
    fprintf('  - %s\n', hFiles(k).name);
end
fprintf('================================================================\n\n');


%% Section 5: Deploy to Firmware
fprintf('\n================================================================\n');
fprintf(' [Section 5] Deploying Generated Algorithm to Firmware...\n');
fprintf('================================================================\n');

if ~exist('rootDir', 'var') || isempty(rootDir) || ~exist(fullfile(rootDir, 'scripts', 'motor.m'), 'file')
    wFile = which('stugverter.m');
    if ~isempty(wFile), rootDir = fileparts(wFile); else, rootDir = pwd; end
end

firmwareAlgorithmDir = fullfile(rootDir, '..', 'firmware', 'algorithm');
codegenDir = fullfile(rootDir, 'algorithm_ert_rtw');

if ~exist(codegenDir, 'dir')
    error('Code generation directory "%s" not found. Please run Section 4 first.', codegenDir);
end

if ~exist(firmwareAlgorithmDir, 'dir')
    fprintf('Creating target firmware algorithm directory: %s\n', firmwareAlgorithmDir);
    mkdir(firmwareAlgorithmDir);
end

allSourceFiles = [dir(fullfile(codegenDir, '*.c')); dir(fullfile(codegenDir, '*.h'))];
excludeList = {'ert_main.c', 'ert_main.h'};

deployedCount = 0;
for k = 1:length(allSourceFiles)
    fileName = allSourceFiles(k).name;
    if any(strcmp(fileName, excludeList))
        continue;
    end
    
    srcPath  = fullfile(codegenDir, fileName);
    destPath = fullfile(firmwareAlgorithmDir, fileName);
    copyfile(srcPath, destPath);
    fprintf('  Deployed -> %s\n', fileName);
    deployedCount = deployedCount + 1;
end

fprintf('\nSuccessfully deployed %d file(s) to:\n  %s\n', deployedCount, firmwareAlgorithmDir);
fprintf('================================================================\n');
fprintf(' Deployment complete! To compile firmware and flash target MCU:\n');
fprintf(' >> run(''scripts/upload.m'')\n');
fprintf('================================================================\n\n');
