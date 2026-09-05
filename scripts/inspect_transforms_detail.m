%% inspect_transforms_detail.m
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'models'));
cd(rootDir);
run('init.m');
load_system('foc_controller');

% Check Clarke Transform inports
clarke = 'foc_controller/Clarke Transform';
disp(['Clarke Type: ', get_param(clarke, 'MaskType')]);
disp(['Clarke Mask: ', get_param(clarke, 'MaskValueString')]);

% Check Park Transform inports
park = 'foc_controller/Park Transform';
disp(['Park Type: ', get_param(park, 'MaskType')]);
disp(['Park Mask: ', get_param(park, 'MaskValueString')]);

% Check line handles to Park Transform
lh = get_param(park, 'LineHandles');
for i = 1:length(lh.Inport)
    p = lh.Inport(i);
    if p ~= -1
        sp = get_param(p, 'SrcPortHandle');
        fprintf('Park Inport %d from: %s port %d\n', i, get_param(sp, 'Parent'), get_param(sp, 'PortNumber'));
    end
end
