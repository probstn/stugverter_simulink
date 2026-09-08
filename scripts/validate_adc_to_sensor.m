function results = validate_adc_to_sensor
% Native-block sensor regression, full-model simulation, standalone C build.
root = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(root,'init.m'));
load_system('algorithm');
assert(isempty(find_system('algorithm/adc_to_sensor','LookUnderMasks','all','BlockType','S-Function')));
assert(strcmp(get_param('algorithm/adc_values','OutDataTypeStr'),'Bus: adc_values'));
load_system('stugverter');
assert(strcmp(get_param('stugverter/Processor/Model','ModelName'),'algorithm'));
work = tempname; mkdir(work);
old = Simulink.fileGenControl('getConfig');
cleanup = onCleanup(@() Simulink.fileGenControl('setConfig','config',old));
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'),'CodeGenFolder',fullfile(work,'code'),'createDir',true);
h = 'adc_sensor_validation'; new_system(h);
hcleanup = onCleanup(@() close_system(h,0));
set_param(h,'Solver','FixedStepDiscrete','FixedStep','foc.Ts','StopTime','(length(adc_test_time)-1)*foc.Ts');
n=12000; t=(0:n-1)'*foc.Ts;
% Stationary nonzero startup, forward/reverse wrap crossings, stop, acceleration.
theta=[ones(1000,1)*2.1; 2.1+(1:4000)'*1800*foc.Ts; ...
    2.1+4000*1800*foc.Ts-(1:4000)'*1800*foc.Ts; ...
    ones(1000,1)*2.1; 2.1+0.5*2e4*((1:2000)'*foc.Ts).^2];
counts=uint16([mod((0:n-1)',4096), mod((0:n-1)'+1371,4096), mod((0:n-1)'+2742,4096), ...
    round(2048+2047*sin(theta)),round(2048+2047*cos(theta))]);
assignin('base','adc_test_time',t);
names={'ia','ib','ic','resolver_sin','resolver_cos'};
add_block('built-in/BusCreator',[h '/ADC'],'Inputs','5','OutDataTypeStr','Bus: adc_values','NonVirtualBus','on');
for k=1:5
    v=['adc_test_' names{k}]; assignin('base',v,timeseries(counts(:,k),t));
    add_block('built-in/FromWorkspace',[h '/' names{k}],'VariableName',v,'Interpolate','off','OutputAfterFinalValue','Holding final value','SampleTime','foc.Ts');
    line=add_line(h,[names{k} '/1'],['ADC/' num2str(k)]); set_param(line,'Name',names{k});
end
add_block('algorithm/adc_to_sensor',[h '/Sensors']); add_line(h,'ADC/1','Sensors/1');
add_block('built-in/BusSelector',[h '/Measurements'],'OutputSignals','currents,MtrPos,speed'); add_line(h,'Sensors/1','Measurements/1');
for k=1:3
    vars={'measured_currents','measured_position','measured_speed'};
    add_block('built-in/ToWorkspace',[h '/' vars{k}],'VariableName',vars{k},'SaveFormat','Timeseries','MaxDataPoints','inf','Decimation','1');
    add_line(h,['Measurements/' num2str(k)],[vars{k} '/1']);
end
out=sim(h,'ReturnWorkspaceOutputs','on');
i=out.measured_currents.Data; pos=out.measured_position.Data; speed=out.measured_speed.Data;
fprintf('Samples: currents %s, position %s, speed %s; expected %d\n',mat2str(size(i)),mat2str(size(pos)),mat2str(size(speed)),n);
if size(i,1) ~= n, i=reshape(i,3,[])'; end
pos=pos(:); speed=speed(:);
assert(isequal(size(i),[n 3]) && numel(pos)==n && numel(speed)==n);
assert(isa(i,'single') && isa(pos,'single') && isa(speed,'single'));
refI=(double(counts(:,1:3))-2048)*(sensor.I_max/2047);
refPos=mod(atan2(double(counts(:,4))-2048,double(counts(:,5))-2048),2*pi);
d=diff(refPos); d=d-2*pi*round(d/(2*pi)); raw=[0;d/foc.Ts];
refW=filter(sensor.speed_alpha,[1 -(1-sensor.speed_alpha)],raw);
results.current_max_error_A=max(abs(double(i)-refI),[],'all');
results.position_max_error_rad=max(abs(atan2(sin(double(pos)-refPos),cos(double(pos)-refPos))));
results.speed_max_error_rad_s=max(abs(double(speed)-refW));
assert(results.current_max_error_A<2e-5,'Current scaling regression');
assert(results.position_max_error_rad<1e-6,'Angle reconstruction regression');
assert(results.speed_max_error_rad_s<0.05,'Speed estimation regression');
assert(all(speed(1:1000)==0),'Nonzero stationary initial angle creates speed spike');
assert(abs(mean(double(speed(4500:5000)))-1800)<0.1);
assert(abs(mean(double(speed(8500:9000)))+1800)<0.1);
disp(results);
results.type_audit=audit_algorithm_types;
fprintf('Sensor regression and algorithm update PASSED.\n');
% Existing full-profile acceptance checks (run_simulation clears its workspace).
evalin('base',sprintf('run(''%s'')',fullfile(root,'scripts','run_simulation.m')));
fprintf('Generating and compiling algorithm.slx only...\n');
codeOnly=get_param('algorithm','GenCodeOnly');
buildCleanup=onCleanup(@() set_param('algorithm','GenCodeOnly',codeOnly));
set_param('algorithm','GenCodeOnly','off');
slbuild('algorithm');
results.build_folder=work;
results.code_audit=audit_algorithm_code(fullfile(work,'code','algorithm_ert_rtw'));
fprintf('ALL VALIDATION PASSED. Generated code: %s\n',work);
end
