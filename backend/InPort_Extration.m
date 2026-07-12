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
%  File         :  InPort_Extration.m
%
%  Description  :  Extracts Inputs from the Model.
%
% *************************************************************************
function [final_inputs, selected_module_path, selected_module_Name, inports_file_path] = InPort_Extration(frame_model_path, data_folder)
    
    fig = resolveGuiFig(); %#ok<NASGU>
    
    subsystem_name = strsplit(frame_model_path,'/');
    selected_module_Name = subsystem_name{end};
    selected_module_path = frame_model_path;

    fnd_in_port = find_system(selected_module_path, 'FindAll','on','SearchDepth',1,'BlockType','Inport');

    count_in = 1;
    final_inputs = cell(5000, 8);   % Preallocate

    % ? JSON container
    jsonStruct = struct('signal', {}, 'value', {}, 'datatype', {});

    for i = 1:length(fnd_in_port)

        handle_data = get_param(fnd_in_port(i),'data');
        dims = split(handle_data,',');
        dims = str2num(char(dims(2)));

        if dims > 1

            p = tl_get(fnd_in_port(i), 'Signals');
            j = p{1}{1,2};

            final_list = {};
            row = 1;

            if iscell(j{1,1})
                for busIndex = 1:length(j)
                    busStruct = j{busIndex,1};
                    busName   = busStruct{1,1};
                    sigList   = busStruct{1,2};

                    for s = 1:length(sigList)
                        final_list{row,1} = sigList{s,1};
                        final_list{row,2} = busName;
                        row = row + 1;
                    end
                end
            else
                for s = 1:length(j)
                    final_list{row,1} = j{s,1};
                    final_list{row,2} = '';
                    row = row + 1;
                end
            end

            for r = 1:size(final_list,1)

                signalName = final_list{r,1};
                busName    = final_list{r,2};

                final_inputs{count_in,1} = signalName;
                final_inputs{count_in,2} = get_param(fnd_in_port(i),'Name');
                final_inputs{count_in,3} = 'Bus';
                final_inputs{count_in,4} = 'Single';
                final_inputs{count_in,6} = busName;

                dd_path = tl_get(fnd_in_port(i),'output.variable');
                parts = strsplit(dd_path,'/');
                parts{end} = signalName;
                dd_path = ['/Pool/Variables/', strjoin(parts,'/')];

                % VALUE
                cmd = ['dsdd(''GetValue'',','''',dd_path,'''',')'];
                valRaw = evalc('base',cmd);
                val = regexp(valRaw,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match','once');
                numVal = str2double(val);
                if isnan(numVal), numVal = 0; end
                final_inputs{count_in,7} = numVal;

                % TYPE
                cmd = ['dsdd(''GetType'',','''',dd_path,'''',')'];
                typeRaw = evalc('base',cmd);
                typeSplit = strsplit(typeRaw,'=');
                type = datatype_mapping(strtrim(typeSplit{2}));
                final_inputs{count_in,8} = type;

                % ? JSON entry
                jsonStruct(end+1) = struct( ...
                    'signal', signalName, ...
                    'value', numVal, ...
                    'datatype', type);

                count_in = count_in + 1;
            end

        else
            signalName = strrep(get_param(fnd_in_port(i), 'Name'), '_IN_', '_');

            final_inputs{count_in,1} = signalName;
            final_inputs{count_in,2} = '';
            final_inputs{count_in,3} = 'Scalar';
            final_inputs{count_in,4} = 'Single';
            final_inputs{count_in,6} = '';

            dd_path = tl_get(fnd_in_port(i),'output.variable');
            dd_path = ['/Pool/Variables/', dd_path];

            % VALUE
            cmd = ['dsdd(''GetValue'',','''',dd_path,'''',')'];
            rawVal = evalc('base',cmd);
            val = regexp(rawVal,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match','once');
            numVal = str2double(val);
            if isnan(numVal), numVal = 0; end
            final_inputs{count_in,7} = numVal;

            % TYPE
            cmd = ['dsdd(''GetType'',','''',dd_path,'''',')'];
            rawType = evalc('base',cmd);
            typeSplit = strsplit(rawType,'=');
            type = datatype_mapping(strtrim(typeSplit{2}));
            final_inputs{count_in,8} = type;

            % ? JSON entry
            jsonStruct(end+1) = struct( ...
                'signal', signalName, ...
                'value', numVal, ...
                'datatype', type);

            count_in = count_in + 1;
        end
    end
    
    final_inputs = final_inputs(~all(cellfun(@isempty, final_inputs),2), :);

    %----------------------------------
    % ? JSON WRITE (ONLY CHANGE HERE)
    %----------------------------------
    fullFilePath = fullfile(data_folder,'inports.json');
    inports_file_path = fullFilePath;

    rawJson = jsonencode(jsonStruct);
    rawJson = strrep(rawJson, '\/', '/');

    if length(rawJson) > 2
        rawJson = rawJson(2:end-1);
    end

    parts = regexp(rawJson, '\},\{', 'split');

    formattedText = ['[', sprintf('\n')];

    for i = 1:length(parts)
        part = parts{i};
        if length(part) == 1
            part = ['{', part, '}'];
        else 
            if i == 1
                part = [part, '}'];
            elseif i == length(parts)
                part = ['{', part];
            else
                part = ['{', part, '}'];
            end
        end

        formattedText = [formattedText, '  ', strtrim(part)];

        if i < length(parts)
            formattedText = [formattedText, ',', sprintf('\n')];
        else
            formattedText = [formattedText, sprintf('\n')];
        end
    end

    formattedText = [formattedText, ']'];

    fid = fopen(fullFilePath,'w');
    fprintf(fid, '%s', formattedText);
    fclose(fid);

    fprintf('File written: %s\n', fullFilePath);

end

function writeCustomJson(filePath, dataStruct)

    rawJson = jsonencode(dataStruct);

    % ? Remove escaped slash
    rawJson = strrep(rawJson, '\/', '/');

    % Remove outer []
    if length(rawJson) > 2
        rawJson = rawJson(2:end-1);
    end

    % Split objects
    parts = regexp(rawJson, '\},\{', 'split');

    formattedText = ['{', sprintf('\n')];

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

    formattedText = [formattedText, '}'];

    fid = fopen(filePath, 'w');
    fprintf(fid, '%s', formattedText);
    fclose(fid);
end

function datatype = datatype_mapping(datatype)
    % DATATYPE MAPPING
    switch datatype
        case 'UInt16',  datatype = 'uint16';
        case 'Int16',   datatype = 'int16';
        case 'ui8',     datatype = 'uint8';
        case 'Int32',   datatype = 'int32';
        case 'UInt32',  datatype = 'uint32';
        case 'Int8',    datatype = 'int8';
        case 'Si16',    datatype = 'uint16';
        case 'Si8',     datatype = 'uint8';
        case 'Float32', datatype = 'double';
        case 'Boolean', datatype = 'bool';
        otherwise,      datatype = 'double';
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