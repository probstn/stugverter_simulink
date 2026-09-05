% analyze_signals.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');

load_system('foc_system');
set_param('foc_system', 'StopTime', '0.3');
out = sim('foc_system');

logsout = out.logsout;
fprintf('Signals logged in logsout (%d elements):\n', logsout.numElements);
for i = 1:logsout.numElements
    sig = logsout{i};
    fprintf('  Signal %d: %s\n', i, sig.Name);
end

% Let's also check Scopes or add signal logging
