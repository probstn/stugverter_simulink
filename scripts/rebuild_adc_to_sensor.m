function rebuild_adc_to_sensor
% Rebuild the deployable sensor path using native Simulink blocks.
% Run init first. Only algorithm.slx is modified.
load_system('algorithm');
p = 'algorithm/adc_to_sensor';
lines=find_system(p,'FindAll','on','SearchDepth',1,'Type','line');
delete_line(lines);
blocks=find_system(p,'SearchDepth',1,'Type','Block');
for k=2:numel(blocks)
    if ~ismember(get_param(blocks{k},'BlockType'),{'Inport','Outport'})
        delete_block(blocks{k});
    end
end
b(p,'Inport','adc_values','OutDataTypeStr','Bus: adc_values');
b(p,'BusSelector','ADC channels','OutputSignals','ia,ib,ic,resolver_sin,resolver_cos');
w(p,'adc_values/1','ADC channels/1');
s = [p '/Current measurement']; sub(s);
for k=1:3
    n = char('a'+k-1);
    b(s,'Inport',['adc_i' n],'Port',num2str(k),'OutDataTypeStr','uint16');
    b(s,'DataTypeConversion',['Single ' n],'OutDataTypeStr','single');
    b(s,'Bias',['Remove midpoint ' n],'Bias','-single(sensor.ADC_mid)');
    b(s,'Gain',['Amperes ' n],'Gain','single(sensor.I_max)/single(sensor.ADC_span)');
    b(s,'Outport',['i' n '_A'],'Port',num2str(k));
    w(s,['adc_i' n '/1'],['Single ' n '/1']);
    w(s,['Single ' n '/1'],['Remove midpoint ' n '/1']);
    w(s,['Remove midpoint ' n '/1'],['Amperes ' n '/1']);
    w(s,['Amperes ' n '/1'],['i' n '_A/1']);
    w(p,['ADC channels/' num2str(k)],['Current measurement/' num2str(k)]);
end
set_param(s,'Description','Phase currents [A] = (single(ADC) - ADC_mid) * I_max / ADC_span. Convert before subtracting to avoid unsigned arithmetic.');
arrange(s);
s = [p '/Position measurement']; sub(s);
for k=1:2
    names={'sin','cos'}; n=names{k};
    b(s,'Inport',['adc_' n],'Port',num2str(k),'OutDataTypeStr','uint16');
    b(s,'DataTypeConversion',['Single ' n],'OutDataTypeStr','single');
    b(s,'Bias',['Remove midpoint ' n],'Bias','-single(sensor.ADC_mid)');
    b(s,'Gain',['Normalize ' n],'Gain','single(1)/single(sensor.ADC_span)');
    w(s,['adc_' n '/1'],['Single ' n '/1']);
    w(s,['Single ' n '/1'],['Remove midpoint ' n '/1']);
    w(s,['Remove midpoint ' n '/1'],['Normalize ' n '/1']);
end
b(s,'Trigonometry','atan2 sin cos','Operator','atan2');
b(s,'Constant','Full turn','Value','single(2*pi)');
b(s,'Math','Wrap to one turn','Operator','mod');
b(s,'Outport','position_rad');
w(s,'Normalize sin/1','atan2 sin cos/1'); w(s,'Normalize cos/1','atan2 sin cos/2');
w(s,'atan2 sin cos/1','Wrap to one turn/1'); w(s,'Full turn/1','Wrap to one turn/2');
w(s,'Wrap to one turn/1','position_rad/1');
set_param(s,'Description','Mechanical resolver angle [rad], in [0, 2*pi). Assumes one resolver cycle per mechanical revolution, matched SIN/COS calibration.'); arrange(s);
w(p,'ADC channels/4','Position measurement/1'); w(p,'ADC channels/5','Position measurement/2');
s = [p '/Speed from position']; sub(s);
b(s,'Inport','position_rad','OutDataTypeStr','single');
b(s,'UnitDelay','Previous position','SampleTime','foc.Ts','InitialCondition','single(0)');
b(s,'Sum','Position difference','Inputs','+-');
b(s,'Gain','Turns','Gain','single(1)/single(2*pi)');
b(s,'Rounding','Nearest turn','Operator','round');
b(s,'Gain','Whole turns in radians','Gain','single(2*pi)');
b(s,'Sum','Unwrap difference','Inputs','+-');
b(s,'Constant','True','Value','true');
b(s,'UnitDelay','Have previous sample','SampleTime','foc.Ts','InitialCondition','false');
b(s,'Constant','Zero','Value','single(0)');
b(s,'Switch','Suppress first difference','Criteria','u2 ~= 0');
b(s,'Gain','Radians per second','Gain','single(1)/single(foc.Ts)');
b(s,'Gain','New speed weight','Gain','single(sensor.speed_alpha)');
b(s,'UnitDelay','Previous filtered speed','SampleTime','foc.Ts','InitialCondition','single(0)');
b(s,'Gain','Previous speed weight','Gain','single(1)-single(sensor.speed_alpha)');
b(s,'Sum','Low pass filter','Inputs','++');
b(s,'Outport','speed_rad_s');
w(s,'position_rad/1','Previous position/1'); w(s,'position_rad/1','Position difference/1');
w(s,'Previous position/1','Position difference/2');
w(s,'Position difference/1','Turns/1'); w(s,'Turns/1','Nearest turn/1');
w(s,'Nearest turn/1','Whole turns in radians/1');
w(s,'Position difference/1','Unwrap difference/1'); w(s,'Whole turns in radians/1','Unwrap difference/2');
w(s,'True/1','Have previous sample/1'); w(s,'Have previous sample/1','Suppress first difference/2');
w(s,'Unwrap difference/1','Suppress first difference/1'); w(s,'Zero/1','Suppress first difference/3');
w(s,'Suppress first difference/1','Radians per second/1'); w(s,'Radians per second/1','New speed weight/1');
w(s,'New speed weight/1','Low pass filter/1'); w(s,'Previous filtered speed/1','Previous speed weight/1');
w(s,'Previous speed weight/1','Low pass filter/2'); w(s,'Low pass filter/1','Previous filtered speed/1'); w(s,'Low pass filter/1','speed_rad_s/1');
set_param(s,'Description',sprintf('Mechanical speed [rad/s] at foc.Ts. Shortest signed angle difference; requires motion < pi rad/sample. First sample outputs zero. First-order low-pass: w = alpha*w_raw + (1-alpha)*w_prev; cutoff sensor.speed_fc.')); arrange(s);
w(p,'Position measurement/1','Speed from position/1');
b(p,'Mux','Phase currents abc','Inputs','3');
for k=1:3, w(p,['Current measurement/' num2str(k)],['Phase currents abc/' num2str(k)]); end
b(p,'BusCreator','Physical measurements','Inputs','3','OutDataTypeStr','Bus: algo_measurement','NonVirtualBus','on','InheritFromInputs','off');
w(p,'Position measurement/1','Physical measurements/1','MtrPos');
w(p,'Phase currents abc/1','Physical measurements/2','currents');
w(p,'Speed from position/1','Physical measurements/3','speed');
b(p,'Outport','measurements','OutDataTypeStr','Bus: algo_measurement'); w(p,'Physical measurements/1','measurements/1');
set_param(p,'Description','Five uint16 ADC channels -> phase currents [A], mechanical position [rad], and speed [rad/s]. All conversion and estimator state live in algorithm.slx for standalone generated code.');
arrange(p);
set_param([p '/Current measurement'],'Position',[230 40 420 150],'ContentPreviewEnabled','off');
set_param([p '/Position measurement'],'Position',[230 235 420 305],'ContentPreviewEnabled','off');
set_param([p '/Speed from position'],'Position',[485 300 665 355],'ContentPreviewEnabled','off');
set_param([p '/ADC channels'],'Position',[140 55 145 285]);
set_param([p '/adc_values'],'Position',[40 163 70 177]);
set_param([p '/Phase currents abc'],'Position',[480 40 485 150]);
set_param([p '/Physical measurements'],'Position',[735 170 740 290]);
set_param([p '/measurements'],'Position',[815 223 845 237]);
Simulink.BlockDiagram.routeLine(find_system(p,'FindAll','on','SearchDepth',1,'Type','line'));
save_system('algorithm');
end
function b(p,type,name,varargin)
if getSimulinkBlockHandle([p '/' name]) == -1
    add_block(['built-in/' type],[p '/' name],varargin{:});
else
    set_param([p '/' name],varargin{:});
end
end
function sub(p)
add_block('built-in/SubSystem',p);
end
function w(p,a,z,varargin)
h=add_line(p,a,z,'autorouting','on');
if ~isempty(varargin), set_param(h,'Name',varargin{1}); end
end
function arrange(p)
Simulink.BlockDiagram.arrangeSystem(p);
end
