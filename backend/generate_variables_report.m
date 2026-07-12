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
%  File         :  generate_variables_report.m
%
%  Description  :  Generates Variables page in the Reports.
%
% *************************************************************************
function reportFile = generate_variables_report(excelPaths, templatesDir, reportsDir)

if nargin < 3
    error('Usage: generate_variables_report(excelPaths, templatesDir, reportsDir)');
end

% Normalize input
if ischar(excelPaths)
    excelPaths = {excelPaths};
end

modules = struct([]);

for k = 1:numel(excelPaths)

    excelPath = excelPaths{k};
    baseDir   = fileparts(excelPath);
    [~, moduleName] = fileparts(excelPath);
    
    [~, submodule_name, ~] = fileparts(excelPath);
    submodule_name = strrep(submodule_name, '_TestCase', '');
    logFile   = fullfile(fileparts(excelPath), 'commandLog.txt');
    commandLog(logFile, 'Generating Coverage report for %s ...', submodule_name);

    % Locate *_data folder
    d = dir(fullfile(baseDir, '*_data'));
    if isempty(d)
        error('No *_data folder found for module: %s', moduleName);
    end
    dataDir = fullfile(baseDir, d(1).name);

    modules(k).name       = moduleName;
    modules(k).inputs     = struct([]);
    modules(k).parameters = struct([]);
    modules(k).outputs    = struct([]);

    %% ---------------- INPUTS (JSON) ----------------
    inFile = fullfile(dataDir, 'inports.json');
    if exist(inFile,'file')

        rawText = strtrim(fileread(inFile));
        data = jsondecode(rawText);

        for i = 1:numel(data)
            if isfield(data(i),'signal')
                modules(k).inputs(i).name     = strtrim(data(i).signal);
                modules(k).inputs(i).value    = data(i).value;
                modules(k).inputs(i).datatype = data(i).datatype;
            end
        end
    end

    %% ---------------- PARAMETERS (JSON) ----------------
    paramFile = fullfile(dataDir, 'parameter.json');

    if exist(paramFile, 'file')

        rawText = strtrim(fileread(paramFile));

        if isempty(rawText) || strcmp(rawText, '{}')
            data = [];
        else
            data = jsondecode(rawText);
        end

        idx = 1;

        for i = 1:numel(data)
            if isfield(data(i), 'source') && strcmp(data(i).source, 'model')
                if isfield(data(i), 'name') && ~isempty(data(i).name)
                    modules(k).parameters(idx).name = strtrim(data(i).name);
                    if isfield(data(i), 'value')
                        val = data(i).value;
                        if isnumeric(val)
                            modules(k).parameters(idx).value = mat2str(val);
                        elseif ischar(val)
                            modules(k).parameters(idx).value = val;
                        elseif isstring(val)
                            modules(k).parameters(idx).value = char(val);
                        else
                            modules(k).parameters(idx).value = char(string(val));
                        end
                    else
                        modules(k).parameters(idx).value = '';
                    end
                    if isfield(data(i), 'datatype')
                        modules(k).parameters(idx).datatype = data(i).datatype;
                    else
                        modules(k).parameters(idx).datatype = '';
                    end

                    idx = idx + 1;
                end
            end
        end
    end

    %% ---------------- OUTPUTS (JSON) ----------------
    outFile = fullfile(dataDir,'outports.json');
    if exist(outFile,'file')

        rawText = strtrim(fileread(outFile));
        data = jsondecode(rawText);

        idx = 1;
        for i = 1:numel(data)
            if isfield(data(i),'signal')
                modules(k).outputs(idx).name = strtrim(data(i).signal);
                idx = idx + 1;
            end
        end
    end

end

html = fileread(fullfile(templatesDir,'variables_template.html'));
html = strrep(html,'{{ title }}','Variables Summary');

html = inject_modules_into_variables(html, modules);

% Remove leftover template tags
html = regexprep(html,'\{%.*?\%\}','');

if ~exist(reportsDir,'dir')
    mkdir(reportsDir);
end

reportFile = fullfile(reportsDir,'variables.html');
fid = fopen(reportFile,'w');
fwrite(fid,html);
fclose(fid);

end


function html = inject_modules_into_variables(html, modules)

block = '';

for k = 1:numel(modules)

    m = modules(k);
    m.name = strrep(m.name, '_TestCase', '');
    % ---------- OPEN CARD ----------
    block = [block ...
        '<div class="card">' ...
        '<div class="module-title">Module: ' m.name '</div>'];

    %  INPUTS 
    block = [block ...
        '<h3>Inputs</h3>' ...
        '<table>' ...
        '<tr>' ...
            '<th>S. No</th>' ...
            '<th>Variable Name</th>' ...
            '<th>Data Type</th>' ...
            '<th>Value</th></tr>'];

    for i = 1:numel(m.inputs)
        block = [block ...
            '<tr>' ...
                '<td>' num2str(i) '</td>' ...
                '<td>' m.inputs(i).name '</td>' ...
                '<td>' m.inputs(i).datatype '</td>' ...
                '<td>' m.inputs(i).value '</td>' ...
            '</tr>'];
    end
    block = [block '</table>'];
    
    %  OUTPUTS 
    block = [block ...
        '<h3>Outputs</h3>' ...
        '<table>' ...
        '<tr><th>S. No</th><th>Variable Name</th></tr>'];

    for i = 1:numel(m.outputs)
        block = [block ...
            '<tr>' ...
                '<td>' num2str(i) '</td>' ...
                '<td>' m.outputs(i).name '</td>' ...
            '</tr>'];
    end
    block = [block '</table>'];


    %  PARAMETERS 
    block = [block ...
        '<h3>Parameters</h3>' ...
        '<table>' ...
        '<tr>' ...
            '<th>S. No</th>' ...
             '<th>Variable Name</th>' ...
             '<th>Data Type</th>' ...
             '<th>Value</th></tr>'];

    for i = 1:numel(m.parameters)
        block = sprintf([ ...
            '%s<tr>' ...
            '<td>%d</td>' ...
            '<td>%s</td>' ...
            '<td>%s</td>' ...
            '<td>%s</td>' ...
            '</tr>' ...
        ], ...
        block, ...
        i, ...
        char(m.parameters(i).name), ...
        char(m.parameters(i).datatype), ...
        char(m.parameters(i).value) ...
        );
    end
    block = [block '</table>'];

    % ---------- CLOSE CARD ----------
    block = [block '</div>'];
end

    % Replace placeholder ONCE only
    html = regexprep(html,'\{% for module in modules %\}[\s\S]*?\{% endfor %\}',block, 'once');

end