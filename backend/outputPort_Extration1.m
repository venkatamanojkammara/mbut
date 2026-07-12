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
%  File         :  outputPort_Extration1.m
%
%  Description  :  Extracts Outputs from the Model.
%
% *************************************************************************
function [final_outputs, outports_file_path] = outputPort_Extration1(frame_model_path, data_folder)
 
    fig = resolveGuiFig(); %#ok<NASGU>
    subsystem_name=strsplit(frame_model_path,'/');
    sz_subsystem= length(subsystem_name);
    NM=char(subsystem_name(sz_subsystem)); %#ok<NASGU>
    BP=frame_model_path;
    first=0; %#ok<NASGU>
    count_in=1;
    fnd_out_port = find_system(BP, 'FindAll', 'on', 'SearchDepth', 1, 'BlockType', 'Outport');
    ouput_port_names = cell(length(fnd_out_port), 6); %#ok<NASGU>
    outputport_dimensions = cell(length(fnd_out_port), 1);

    % ? SAME LOGIC, ONLY SAFE PREALLOC
    final_outputs=cell(5000,8);
    % ? JSON container (ONLY FOR OUTPUT)
    jsonStruct = struct('signal', {}, 'value', {}, 'datatype', {});


    for i = 1:length(fnd_out_port)
        ouput_port_names{i, 1} = get_param(fnd_out_port(i), 'Name');
        handle_data = get_param(fnd_out_port(i),'data');
        dims=split(handle_data,',');
        dims=dims(2);
        dims = str2num(char(dims)); %#ok<ST2NM>
        outputport_dimensions{i} = dims;
        if dims > 1
            p= tl_get(fnd_out_port(i), 'Signals');
            j=p{1}{1,2};
            if iscell(j{1,1})
                j_length=length(j);
                for j_l=1:j_length
                    sub_bus_length=length(j{j_l,1}{1,2});
                    for sub_bus=1:sub_bus_length
                        final_outputs{count_in,1 }=j{j_l,1}{1,2}{sub_bus,1};
                        final_outputs{count_in, 2} = get_param(fnd_out_port(i), 'Name');
                        final_outputs{count_in, 3} = 'Bus';
                        final_outputs{count_in, 4} = 'Single';
                        final_outputs{count_in, 6} = '';
                        final_outputs{count_in,7} = [];   % leave empty
                        count_in=count_in+1;
                    end
                end
               fprintf('The j is a struct.\n');
            else
                numberOfRows = length(j);
                first=first+1;
                try
                    Bus_signal_names_in_model=tl_get(fnd_out_port(i),'signals');
                    Bus_signal_names_in_model=Bus_signal_names_in_model{1,1}{1,2};
                catch
                    msgbox('tl_get not working properly. Please restart the matlab or Add TargetLink path to MATLAB', 'Warning');
                end
                for l=1:numberOfRows
                    count_in=count_in+1; 
                    try
                        output_name = strsplit(tl_get(fnd_out_port(i),['output','(',num2str(l),')','.','variable']), '/');
                        output_name =output_name{end};
                        if ~any(contains(Bus_signal_names_in_model, output_name))
                            final_outputs{count_in,1 }=output_name;
                        else
                            final_outputs{count_in,1 }= Bus_signal_names_in_model{l};
                        end
                    catch
                        final_outputs{count_in,1 }=j{l,1};
                    end
                    final_outputs{count_in, 2} = get_param(fnd_out_port(i), 'Name');
                    final_outputs{count_in, 3} = 'Bus';
                    final_outputs{count_in, 4} = 'Single';
                    final_outputs{count_in, 5} = outputport_dimensions{i}';
 
                    % ? SAME: no value computed
                    final_outputs{count_in,7} = [];
                end
            end
        else
            if count_in==1
                final_outputs{count_in,1 } = get_param(fnd_out_port(i), 'Name');
                final_outputs{count_in, 2} = '';
                final_outputs{count_in, 3} = 'Scalar';
                final_outputs{count_in, 4} = 'Single';
                final_outputs{count_in, 6} = '';
                dd_path = tl_get(fnd_out_port(i),'output.variable');
                dd_path = ['/Pool/Variables/',dd_path];
                dsdd_comand = ['dsdd(''GetValue'',','''', dd_path, '''',')'];
                initial_value = evalc('base',dsdd_comand);
 
                 val = regexp(initial_value,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match','once');

                 numVal = str2double(val);
 
                 if isempty(numVal) || isnan(numVal)

                     numVal = 0;

                 end
 
                 final_outputs{count_in,7} = numVal;
 
                 count_in=count_in+1;
 
            else

                count_in=count_in+1;
 
                final_outputs{count_in,1 } = get_param(fnd_out_port(i), 'Name');

                final_outputs{count_in, 2} = '';

                final_outputs{count_in, 3} = 'Scalar';

                final_outputs{count_in, 4} = 'Single';

                final_outputs{count_in, 6} = '';
 
                dd_path = tl_get(fnd_out_port(i),'output.variable');

                dd_path = ['/Pool/Variables/',dd_path];
 
                dsdd_comand = ['dsdd(''GetValue'',','''', dd_path, '''',')'];

                initial_value = evalc('base',dsdd_comand);
 
                val = regexp(initial_value,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match','once');

                numVal = str2double(val);
 
                if isempty(numVal) || isnan(numVal)

                    numVal = 0;

                end
 
                final_outputs{count_in,7} = numVal;
 
                count_in=count_in+1;

            end
 
        end

    end
 
    final_outputs(all(cellfun(@isempty, final_outputs), 2), :) = [];
 
    %----------------------------------

    % ? JSON OUTPUT (USING YOUR VALUES ONLY)

    %----------------------------------

    fullFilePath = fullfile(data_folder, 'outports.json');

    outports_file_path = fullFilePath;
 
    % Build JSON struct from final_outputs ONLY

    for i = 1:size(final_outputs,1)
 
        signalName = final_outputs{i,1};
 
        % ? EXACT VALUE FROM YOUR LOGIC

        val = final_outputs{i,7};

        if isempty(val) || isnan(val)

            val = 0;

        end
 
        % datatype NOT computed in your logic

        datatype = 'unknown';
 
        jsonStruct(end+1) = struct( ...
                'signal', signalName, ...
            'value', val, ...
            'datatype', datatype);
 
    end
 
    % ? FORMAT JSON (2016b safe)

    if isempty(jsonStruct)

        formattedText = '{}';

    else

        rawJson = jsonencode(jsonStruct);

        rawJson = strrep(rawJson, '\/', '/');

        rawJson = rawJson(2:end-1);
 
        parts = regexp(rawJson, '\},\{', 'split');
 
        formattedText = ['[' sprintf('\n')];
 
        for k = 1:length(parts)

            part = parts{k};

            if length(parts) == 1

                part = ['{', part, '}'];

            else 

                if k == 1

                    part = [part, '}'];

                elseif k == length(parts)

                    part = ['{', part];

                else

                    part = ['{', part, '}'];

                end

            end
 
            formattedText = [formattedText, '  ', strtrim(part)];
 
            if k < length(parts)

                formattedText = [formattedText, ',', sprintf('\n')];

            else

                formattedText = [formattedText, sprintf('\n')];

            end

        end
 
        formattedText = [formattedText, ']'];

    end
 
    fid = fopen(fullFilePath, 'w');

    fprintf(fid, '%s', formattedText);

    fclose(fid);
 
    fprintf('File written: %s\n', fullFilePath);
 
end
 

function [numVal, type] = getValueAndType(portHandle, signalName, isBus)

    try
        if isBus
            dd_path = tl_get(portHandle,'output.variable');
            parts = strsplit(dd_path,'/');
            parts{end} = signalName;
            dd_path = ['/Pool/Variables/', strjoin(parts,'/')];
        else
            dd_path = tl_get(portHandle,'output.variable');
            dd_path = ['/Pool/Variables/', dd_path];
        end

        % VALUE
        valCmd = ['dsdd(''GetValue'',''' dd_path ''')'];
        valRaw = evalin('base', valCmd);
        % val = regexp(valRaw,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match','once');
        numVal = str2double(valRaw);
        if isnan(numVal), numVal = 0; end
    catch
        
    end
        try

        % TYPE
        typeCmd = ['dsdd(''GetType'',''' dd_path ''')'];
        typeRaw = evalin('base', typeCmd);
        % typeSplit = strsplit(typeRaw,'=');
        type = datatype_mapping(typeRaw);

    catch
        numVal = 0;
        type = 'unknown';
    end

end

function writeCustomJson(filePath, dataStruct)

    rawJson = jsonencode(dataStruct);

    % ? Fix slash escape
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
 