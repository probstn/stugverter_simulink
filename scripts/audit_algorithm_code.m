function report = audit_algorithm_code(folder)
% Reject double data, math calls, and unsuffixed floating constants in generated
% application/support code. Shared type definitions are not runtime use.
files=[dir(fullfile(folder,'*.c'));dir(fullfile(folder,'*.h'))];
assert(~isempty(files),'No generated code to audit');
report.files_checked=0;
for k=1:numel(files)
    if ismember(files(k).name,{'rtwtypes.h','rt_defines.h'}), continue; end
    code=fileread(fullfile(files(k).folder,files(k).name));
    code=regexprep(code,'/\*[\s\S]*?\*/|//[^\n]*','');
    assert(isempty(regexp(code,'\<(double|real_T|real64_T|time_T|RT_PI|RT_LN_10|RT_LOG10E|RT_E)\>','once')), ...
        'Double type used in %s',files(k).name);
    assert(isempty(regexp(code,'\<(sin|cos|atan2|sqrt|fmod|pow|floor|ceil|round|fabs)\s*\(','once')), ...
        'Double math call in %s',files(k).name);
    % Match the whole literal so a float suffix cannot be skipped by backtracking.
    literals=regexp(code,'(?<![\w.])(?:\d+\.\d*|\.\d+|\d+[eE][+-]?\d+)(?:[eE][+-]?\d+)?[fFlL]?(?![\w.])','match');
    assert(all(cellfun(@(x) any(x(end)=='fF'),literals)), ...
        'Non-single floating constant in %s',files(k).name);
    report.files_checked=report.files_checked+1;
end
fprintf('Generated C audit PASSED: %d files, no double data/math/constants.\n',report.files_checked);
end
