function elapsed = wait_for_xcp(targetAddress, targetPort, localAddress, timeoutSeconds)
%WAIT_FOR_XCP Wait for a complete XCP CONNECT/DISCONNECT exchange over UDP.
arguments
    targetAddress (1,:) char = '192.168.0.10'
    targetPort (1,1) double = 5555
    localAddress (1,:) char = '192.168.0.100'
    timeoutSeconds (1,1) double = 15
end
helper = fullfile(fileparts(mfilename('fullpath')), 'wait_for_xcp.py');
pythonExe = 'C:\winIDEA\Python\python.exe';
if ~exist(pythonExe, 'file'), pythonExe = 'python'; end
command = sprintf('"%s" "%s" --target %s --port %d --local %s --timeout %.3f', ...
    pythonExe, helper, targetAddress, targetPort, localAddress, timeoutSeconds);
[status, output] = system(command);
fprintf('%s', output);
if status ~= 0
    error('stugverter:XcpNotReady', '%s', strtrim(output));
end
token = regexp(output, 'XCP_READY_SECONDS=([0-9.]+)', 'tokens', 'once');
if isempty(token), elapsed = NaN; else, elapsed = str2double(token{1}); end
end
