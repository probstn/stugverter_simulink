%% inspect_we_subsystem1.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_system');

sys = 'foc_system/MTPA Control Reference/Motor_System/Interior PMSM/MTPA_FW_iteratorSelection/no_iterators/fast_and_approximate';
lh = get_param([sys, '/Subsystem1'], 'LineHandles');
for i = 1:length(lh.Inport)
    p = lh.Inport(i);
    if p ~= -1
        sp = get_param(p, 'SrcPortHandle');
        fprintf('Subsystem1 Inport %d connected from: %s port %d\n', i, get_param(sp, 'Parent'), get_param(sp, 'PortNumber'));
    end
end
