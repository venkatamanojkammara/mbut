% *************************************************************************
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
% *************************************************************************
%
%  Created  on  :  26-03-2020
%  Author       :  Venkata Manoj Kammara
%  Department   :  IDSI
%  File         :  load_config_to_workspace.m
%
%  Description  :  Loads the Inputs/Parameters default values into workspace.
%
% *************************************************************************
function load_config_to_workspace(dataDir)

    import matlab.io.*;
    inFile = fullfile(dataDir, 'inports.json');

    if exist(inFile, 'file')

        raw = strtrim(fileread(inFile));
        if ~isempty(raw)
            data = jsondecode(raw);

            for i = 1:numel(data)

                if isfield(data(i), 'signal')
                    name = strtrim(data(i).signal);

                    % ? Value
                    if isfield(data(i), 'value')
                        val = data(i).value;
                    else
                        val = 0;
                    end

                    % ? Datatype
                    if isfield(data(i), 'datatype')
                        dtype = data(i).datatype;
                    else
                        dtype = '';
                    end

                    % ? Convert datatype
                    val = convert_value(val, dtype);

                    % ? Push to base workspace
                    assignin('base', name, val);
                end
            end
        end
    end


    %% ================= PARAMETERS =================
    paramFile = fullfile(dataDir, 'parameter.json');

    if exist(paramFile, 'file')

        raw = strtrim(fileread(paramFile));
        if ~isempty(raw)
            data = jsondecode(raw);

            for i = 1:numel(data)

                if isfield(data(i), 'name')
                    name = strtrim(data(i).name);

                    % ? Value
                    if isfield(data(i), 'value')
                        val = data(i).value;
                    else
                        val = [];
                    end

                    % ? Datatype
                    if isfield(data(i), 'datatype')
                        dtype = data(i).datatype;
                    else
                        dtype = '';
                    end

                    % ? Convert datatype
                    val = convert_value(val, dtype);

                    % ? Push to base workspace
                    if any(name == ' ')
                        name = strrep(name, ' ', '');
                    end
                    assignin('base', name, val);
                end
            end
        end
    end

    disp('? Signals and parameters loaded into Base Workspace');

end

function val = convert_value(val, dtype)

    dtype_lower = lower(string(dtype));
    if contains(dtype_lower, 'eboolean')
        
        if isnumeric(val)
            val = logical(val);   % 0 ? false, nonzero ? true
        elseif ischar(val) || isstring(val)
            val = any(strcmpi(val, ['true', '1']));
        else
            val = logical(val);
        end
        return;
    end

    if ~isempty(val)
        % Cast based on datatype
        switch lower(dtype)
            case {'int8'}
                val = int8(val);
            case {'int16'}
                val = int16(val);
            case {'int32'}
                val = int32(val);
            case {'uint8'}
                val = uint8(val);
            case {'uint16'}
                val = uint16(val);
            case {'uint32'}
                val = uint32(val);
            case {'bool', 'boolean'}
                 val = logical(val);
            case {'double'}
                val = double(val);
            case {'single', 'float'}
                val = single(val);
            otherwise
                val = double(val);
        end

    elseif ischar(val) || isstring(val)
        val = char(val);

    else
        try
            val = double(val);
        catch
            % leave as it is
        end
    end

end