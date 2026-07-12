% ********************************************************************************
%
%    ZZZZZZZZZZ   FFFFFFFFFF
%    ZZZZZZZZZZ   FFFFFFFFFF
%          ZZZ    FFF
%         ZZZ     FFF
%        ZZZ      FFFFFFFF
%       ZZZ       FFFFFFFF
%      ZZZ        FFF
%     ZZZ         FFF
%    ZZZZZZZZZZ   FFF
%    ZZZZZZZZZZ   FFF          FRIEDRICHSHAFEN AG
%
% *********************************************************************************
%
%  Created  on  :  26-03-2020
%  Author       :  Venkata Manoj Kammara
%  Department   :  IDSI
%  File         :  commandLog.m
%
%  Description  :  Creates a commandLog.txt file, and appends the process as text. 
%
% *********************************************************************************
function commandLog(logFile, formatStr, varargin)
    fid = fopen(logFile, 'a');
    if fid == -1
        warning('Could not open log file.');
        return;
    end

    if isempty(varargin)
        msg = formatStr;
    else
        msg = sprintf(formatStr, varargin{:});
    end

    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    fprintf(fid, '[%s]     %s\n', timestamp, msg);

    fclose(fid);
end