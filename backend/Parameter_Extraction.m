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
%  Author       :  Guddeti Jagadeesh Reddy
%  Department   :  IDSIA
%  File         :  Parameter_Extraction.m
%
%  Description  :  Extracts Parameters from the Model.
%
% *************************************************************************
function parameters_file_path = Parameter_Extraction(frame_model_path, data_folder)

    fig = resolveGuiFig(); %#ok<NASGU>
    filePath = mfilename('fullpath'); %#ok<NASGU>
    [filePath,~,~] = fileparts(filePath); %#ok<NASGU>

    % File paths
    fullFilePath = fullfile(data_folder, 'parameter.json');
    parameters_file_path = fullFilePath;

    paramStruct = struct('name', {}, 'value', {}, 'datatype', {}, 'source', {});
    unavailable_params_dd = {};

    %----------------------------------
    % MODEL PARAMETERS
    %----------------------------------
    parameters = find_system(frame_model_path, 'MaskType', 'DFF_PARAM_BLOCK');
    paramNames = get_param(parameters, 'Name');

    if ischar(paramNames)
        paramNames = {regexprep(paramNames, '^DF_c.*?_Get_', '')};
    else
        paramNames = cellfun(@(x) regexprep(x, '^DF_c.*?_Get_', ''), paramNames, 'UniformOutput', false);
    end

    for i = 1:length(paramNames)

        try
            val = evalin('base', paramNames{i});
            datatype = class(val);
        catch
            paramNames{i} = get_param(parameters{i}, 'AttributesFormatString');
            try
                val = evalin('base', paramNames{i});
                datatype = class(val);
            catch
                unavailable_params_dd{end+1} = paramNames{i}; %#ok<AGROW>
                continue;
            end
        end

        paramStruct(end+1) = struct( ...
            'name', paramNames{i}, ...
            'value', makeJsonSafe(val), ...
            'datatype', datatype, ...
            'source', 'model');
    end

    %----------------------------------
    % CONSTANT BLOCKS
    %----------------------------------
    constBlocks = find_system(frame_model_path,...
        'FollowLinks','on','LookUnderMasks','all','BlockType','Constant');

    for i = 1:length(constBlocks)

        blk = constBlocks{i};
        blkName = get_param(blk, 'Name');

        try
            maskValues = get_param(blk, 'data');
            parts = split(maskValues, ',');
        catch
            continue;
        end

        if length(parts) > 2
            dd_path = char(strrep(strrep(parts(3),'}',''),'''',''));
            dd_path = ['/Pool/Variables/', dd_path];

            datatype = evalin('base', ['dsdd(''GetType'',''' dd_path ''')']);
            value    = evalin('base', ['dsdd(''GetValue'',''' dd_path ''')']);

            paramStruct(end+1) = struct( ...
                'name', blkName, ...
                'value', makeJsonSafe(value), ...
                'datatype', datatype, ...
                'source', 'data_dictionary');
        end
    end

    %----------------------------------
    % LOOKUP BLOCKS
    %----------------------------------
    lookupBlocks = find_system(frame_model_path,...
        'FollowLinks','on','LookUnderMasks','all','BlockType','Lookup');

    for i = 1:length(lookupBlocks)

        blk = lookupBlocks{i};
        blkName = get_param(blk, 'Name');

        try
            maskValues = get_param(blk, 'data');
            token = regexp(maskValues, '''table'',\{''variable'',''([^'']+)''\}','tokens');
            dd_path = ['/Pool/Variables/', char(token{1})];

            datatype = evalin('base', ['dsdd(''GetType'',''' dd_path ''')']);
            value    = evalin('base', ['dsdd(''GetValue'',''' dd_path ''')']);

            paramStruct(end+1) = struct( ...
                'name', blkName, ...
                'value', makeJsonSafe(value), ...
                'datatype', datatype, ...
                'source', 'lookup_table');
        catch
            disp('Lookup extraction failed');
        end
    end

    %----------------------------------
    % ? FORMAT & WRITE MAIN JSON
    %----------------------------------
    writeCustomJson(fullFilePath, paramStruct);

    fprintf('File written: %s\n', fullFilePath);

    %----------------------------------
    % ? UNAVAILABLE PARAMETERS (STRUCTURED)
    %----------------------------------
    if ~isempty(unavailable_params_dd)

        unavailableStruct = struct('name', {}, 'value', {}, 'datatype', {}, 'source', {});

        for i = 1:length(unavailable_params_dd)
            unavailableStruct(end+1) = struct( ...
                'name', unavailable_params_dd{i}, ...
                'value', 'N/A', ...
                'datatype', 'unknown', ...
                'source', 'unavailable');
        end

        unavailPath = fullfile(data_folder, 'unavailable_params.json');

        writeCustomJson(unavailPath, unavailableStruct);

        msgbox('Few parameters unavailable. Check unavailable_params.json','Warning');
    end

end

%----------------------------------
% ? JSON FORMATTER (FIXES ALL ISSUES)
%----------------------------------
function writeCustomJson(filePath, dataStruct)

    rawJson = jsonencode(dataStruct);

    % ? Fix slash escaping
    rawJson = strrep(rawJson, '\/', '/');

    % Remove outer []
    if length(rawJson) > 2
        rawJson = rawJson(2:end-1);
    end

    % Split objects
    parts = regexp(rawJson, '\},\{', 'split');

    formattedText = ['[', sprintf('\n')];

    for i = 1:length(parts)

        part = parts{i};

        if i == 1
            part = [part, '}'];
        elseif i == length(parts)
            part = ['{', part];
        else
            part = ['{', part, '}'];
        end

        formattedText = [formattedText, '  ', strtrim(part)];

        if i < length(parts)
            formattedText = [formattedText, ',', sprintf('\n')];
        else
            formattedText = [formattedText, sprintf('\n')];
        end
    end

    formattedText = [formattedText, ']'];

    fid = fopen(filePath, 'w');
    fprintf(fid, '%s', formattedText);
    fclose(fid);

end

%----------------------------------
% ? VALUE SAFETY FUNCTION
%----------------------------------
function val = makeJsonSafe(v)

    if isnumeric(v) || islogical(v)
        val = v;

    elseif ischar(v)
        val = v;

    elseif iscell(v)
        try
            val = cellfun(@makeJsonSafe, v, 'UniformOutput', false);
        catch
            val = 'unsupported_cell';
        end

    else
        try
            val = char(string(v));
        catch
            val = 'unsupported_type';
        end
    end
end

function out = formatValueWithType(value, datatype)
    % Convert value to string
    if isnumeric(value)
        valStr = mat2str(value);
    else
        parsed = str2num(char(value)); %#ok<ST2NM>
        if ~isempty(parsed)
            valStr = mat2str(parsed);
        else
            valStr = char(value);
        end
    end

    % Detect array vs scalar
    if isnumeric(value) && numel(value) > 1
        % Array ? double brackets
        out = ['[', valStr, ',', datatype, ']'];
        out = ['[', out, ']'];   % extra []
    else
        % Scalar
        out = ['[', valStr, ',', datatype, ']'];
    end
end

function fig = resolveGuiFig()
    fig = gcbf;
    if isempty(fig) || ~ishandle(fig)
        fig = gcf;
    end
    if isempty(getappdata(fig,'rightPanel'))
        figs = findall(0,'Type','figure');
        for k = 1:numel(figs)
            if ~isempty(getappdata(figs(k),'rightPanel'))
                fig = figs(k);
                return;
            end
        end
    end
end

function setStatus(fig, msg)
    h = getappdata(fig,'statusText');
    if ~isempty(h) && ishandle(h)
        set(h,'String',msg);
        drawnow;
    end
    pushWS(fig,'STATUS',msg);
end

function pushWS(fig,key,value)

    if nargin < 3
        value = getappdata(fig,key);
    end

    try
        S = evalin('base','GUI_STATE');
        if ~isstruct(S), S = struct(); end
    catch
        S = struct();
    end

    if ~isvarname(key)
        key = matlab.lang.makeValidName(key);
    end

    S.(key) = value;
    assignin('base','GUI_STATE',S);
end