%% flash_target.m
% =========================================================================
% COMPILE & FLASH FIRMWARE TO AURIX TC387 VIA WINIDEA
% =========================================================================
% Compiles the firmware project using multi-threaded TriCore GCC,
% synchronizes the A2L file, connects to winIDEA via the Python API,
% flashes firmware.elf to the TC387 target MCU, and resumes execution.

fprintf('\n================================================================\n');
fprintf(' [FLASH] Compiling & Flashing AURIX TC387 via winIDEA...\n');
fprintf('================================================================\n');

if exist('resolve_simulink_dir', 'file') == 2
    simulinkDir = resolve_simulink_dir();
else
    try
        proj = currentProject;
        simulinkDir = proj.RootFolder;
    catch
        candidates = {pwd, fullfile(pwd, 'simulink'), fileparts(pwd), ...
                      fullfile(fileparts(pwd), 'simulink'), ...
                      'C:\Users\probst\Desktop\stugverter\simulink'};
        simulinkDir = pwd;
        for k = 1:length(candidates)
            if exist(fullfile(candidates{k}, 'scripts', 'init.m'), 'file')
                simulinkDir = candidates{k};
                break;
            end
        end
    end
end

if ~exist(fullfile(simulinkDir, 'scripts', 'init.m'), 'file')
    simulinkDir = fileparts(fileparts(mfilename('fullpath')));
end

projectRoot = fileparts(simulinkDir);
firmwareDir = fullfile(projectRoot, 'firmware');
buildPy     = fullfile(firmwareDir, 'build.py');

% 1. Compile firmware using TriCore GCC build script
fprintf('Building firmware with TriCore GCC (firmware/build.py)...\n');
tic;
[status, cmdOut] = system(sprintf('python "%s"', buildPy));
buildElapsed = toc;

if status ~= 0
    fprintf('\n[!] Build output:\n%s\n', cmdOut);
    error('Firmware build failed with exit code %d.', status);
end
fprintf('Firmware build completed successfully in %.2f s.\n', buildElapsed);

% 2. Download and Run via winIDEA Python API
fprintf('\nConnecting to winIDEA and flashing target AURIX TC387...\n');

winideaPython = 'C:\winIDEA\Python\python.exe';
if ~exist(winideaPython, 'file')
    winideaPython = 'python';
end

flashPyCode = sprintf([...
    'import isystem.connect as ic\n', ...
    'import time, sys\n', ...
    'try:\n', ...
    '    cm = ic.ConnectionMgr()\n', ...
    '    cm.connectMRU('''')\n', ...
    '    loader = ic.CLoaderController(cm)\n', ...
    '    exec_ctrl = ic.CExecutionController(cm)\n', ...
    '    debug_ctrl = ic.CDebugFacade(cm)\n', ...
    '    print("[*] Connected to winIDEA. Downloading firmware.elf...")\n', ...
    '    loader.download()\n', ...
    '    print("[*] Flashing complete. Resetting target into the new image...")\n', ...
    '    exec_ctrl.resetAndRun()\n', ...
    '    time.sleep(0.5)\n', ...
    '    st = exec_ctrl.getCPUStatus()\n', ...
    '    isr = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_foc_isr_counter")\n', ...
    '    d0 = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_duty_u")\n', ...
    '    d1 = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_duty_v")\n', ...
    '    d2 = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_duty_w")\n', ...
    '    gates = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "g_gate_drivers_enabled")\n', ...
    '    en = debug_ctrl.evaluate(ic.IConnectDebug.fMonitor, "control_enable_request")\n', ...
    '    print(f"[+] AURIX running: {st.isRunning()}, ISR count: {isr.getInt()}, PWM duty: [{d0.getFloat():.4f}, {d1.getFloat():.4f}, {d2.getFloat():.4f}], gates: {gates.getInt()}, enable request: {en.getInt()}")\n', ...
    '    if gates.getInt() != 0 or en.getInt() != 0:\n', ...
    '        raise RuntimeError("unsafe boot state: gate drivers or control request active")\n', ...
    'except Exception as e:\n', ...
    '    print(f"[!] winIDEA error: {e}", file=sys.stderr)\n', ...
    '    sys.exit(1)\n' ...
]);

flashPyFile = fullfile(firmwareDir, 'flash_target.py');
fid = fopen(flashPyFile, 'w');
if fid == -1
    error('Failed to create temporary flash script: %s', flashPyFile);
end
fwrite(fid, flashPyCode);
fclose(fid);

[flashStatus, flashOut] = system(sprintf('"%s" "%s"', winideaPython, flashPyFile));
if exist(flashPyFile, 'file')
    delete(flashPyFile);
end

if flashStatus ~= 0
    fprintf('%s\n', flashOut);
    warning('winIDEA flash operation reported an error. Please ensure winIDEA is open and connected to the AURIX TC387 target.');
else
    fprintf('%s\n', flashOut);
    addpath(fullfile(simulinkDir, 'scripts'));
    wait_for_xcp('192.168.0.10', 5555, '192.168.0.100', 15);
    fprintf('================================================================\n');
    fprintf(' Target AURIX TC387 flashed; Ethernet and XCP are ready!\n');
    fprintf('================================================================\n\n');
end
