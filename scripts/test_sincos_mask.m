% test_sincos_mask.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(rootDir)
    rootDir = pwd;
end
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);

load_system('foc_controller');
sc = 'foc_controller/SinCos Embedded Optimized';
names = get_param(sc, 'MaskNames');
fprintf('SinCos Embedded Optimized mask parameters in foc_controller:\n');
for i = 1:length(names)
    fprintf('  %s = %s\n', names{i}, get_param(sc, names{i}));
end

m2e = 'foc_controller/Mechanical to Electrical Position';
fprintf('\nMechanical to Electrical Position mask parameters in foc_controller:\n');
m2e_names = get_param(m2e, 'MaskNames');
for i = 1:length(m2e_names)
    fprintf('  %s = %s\n', m2e_names{i}, get_param(m2e, m2e_names{i}));
end
