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
%  File         :  push_paramters_to_workspace.m
%
%  Description  :  Adds the parameters data into Base Workspace.
%
% *************************************************************************
function push_paramters_to_workspace(parameters_file_path)

    fig = resolveGuiFig();

    fid = fopen(parameters_file_path, 'r');
    if fid == -1
        error('Cannot open the file: %s', parameters_file_path);
    end

    % Read entire file
    rawText = fread(fid, '*char')';
    fclose(fid);

    if isempty(rawText)
        warning('Empty JSON file.');
        return;
    end

    try
        data = jsondecode(rawText);
    catch
        error('JSON parsing failed. Check file format.');
    end

    for i = 1:length(data)

        try
            varName = strtrim(data(i).name);
            val     = data(i).value;
            typeStr = datatype_mapping(strtrim(data(i).datatype));
        catch
            continue;
        end

        try
            switch lower(typeStr)
                case 'double'
                    val = double(val);
                case 'single'
                    val = single(val);
                case 'int8'
                    val = int8(val);
                case 'uint8'
                    val = uint8(val);
                case 'int16'
                    val = int16(val);
                case 'uint16'
                    val = uint16(val);
                case 'int32'
                    val = int32(val);
                case 'uint32'
                    val = uint32(val);
                case 'bool'
                    val = logical(val);
                otherwise
                    val = double(val);
            end
        catch
            warning('Failed to cast %s to %s', varName, typeStr);
        end
        assignin('base', varName, val);

    end

end

function datatype = datatype_mapping(datatype)
 
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
        case 'eBoolean', datatype = 'bool';
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