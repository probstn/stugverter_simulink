function report = audit_algorithm_types
% Check active compiled ports, including library blocks, for double signals.
load_system('algorithm');
feval('algorithm',[],[],[],'compile');
cleanup=onCleanup(@() feval('algorithm',[],[],[],'term'));
blocks=find_system('algorithm','LookUnderMasks','all','FollowLinks','on', ...
    'MatchFilter',@Simulink.match.activeVariants,'Type','Block');
report.blocks_checked=numel(blocks);
report.double_ports={};
for k=1:numel(blocks)
    types=get_param(blocks{k},'CompiledPortDataTypes');
    fields=fieldnames(types);
    for j=1:numel(fields)
        vals=types.(fields{j});
        if any(strcmp(vals,'double'))
            report.double_ports{end+1}=[blocks{k} ':' fields{j}]; %#ok<AGROW>
        end
    end
end
assert(isempty(report.double_ports),'Double signals found: %s',strjoin(report.double_ports,', '));
% Check the bus vector dimensions and scalar meanings at the consumer boundary.
selector=find_system('algorithm/current_control','SearchDepth',1,'BlockType','BusSelector');
selector=selector{1};
ports=get_param(selector,'PortHandles');
% Locate by selected field name, rather than assuming selector output order.
fields=strsplit(get_param(selector,'OutputSignals'),',');
for k=1:numel(fields)
    width=get_param(ports.Outport(k),'CompiledPortWidth');
    if strcmp(fields{k},'currents'), expected=3; else, expected=1; end
    assert(width==expected,'Unexpected width for %s',fields{k});
end
fprintf('Type audit PASSED: %d active blocks, no double ports.\n',report.blocks_checked);
end
