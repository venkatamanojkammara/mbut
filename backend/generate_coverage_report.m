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
%  File         :  generate_coverage_report.m
%
%  Description  :  Generates Coverage Page in Report.
%
% *************************************************************************
function reportFile = generate_coverage_report(excelPaths, templatesDir, reportsDir)
fig = resolveGuiFig();
if nargin < 3
    error('Usage: generate_coverage_report(excelPaths, templatesDir, reportsDir)');
end


if ischar(excelPaths)
    excelPaths = {excelPaths};
end

numExcels = numel(excelPaths);
templatePath = fullfile(templatesDir, 'coverage_template_consolidated.html');
if ~exist(templatePath, 'file')
    error('Coverage template not found: %s', templatePath);
end

html = fileread(templatePath);

modules = struct([]);

for k = 1:numExcels

    excelPath = excelPaths{k};
    baseDir   = fileparts(excelPath);
    [~, moduleName] = fileparts(excelPath);
    
    [~, submodule_name, ~] = fileparts(excelPath);
    submodule_name = strrep(submodule_name, '_TestCase', '');
    logFile   = fullfile(fileparts(excelPath), 'commandLog.txt');
    commandLog(logFile, 'Generating Coverage report for %s ...', submodule_name);

    frame = dir(fullfile(baseDir, '*_tl.slx'));
    [~, frame_name, ~] = fileparts(frame.name);
    
    cd(baseDir);
    coverageDir = fullfile(baseDir, 'CodeCoverageReport');
    
    code_coverage_type = getappdata(fig, 'coverageTypeDropdown');
    try
        code_coverage_type_value = code_coverage_type.Value;
    catch
        code_coverage_type_value = 2;
    end
    if code_coverage_type_value == 1
		msgbox('Select any Coverage Type', 'Warning');
		return;
    elseif code_coverage_type_value == 2
        code_coverage_type_value = 1;
    else 
        code_coverage_type_value = 2;
    end
	
    try
        hMainTLDialog = find_system(frame_name,'MaskType', 'TL_MainDialog');
        tl_set(hMainTLDialog, 'codecoveragelevel', code_coverage_type_value,'codeopt.cleancode',0,'logopt.globalloggingmode',1);
        tlCodeCoverage('GenerateReport',frame_name,'OutputDirectory', coverageDir, 'Show','off');
    catch ME
        msgbox(ME.message, 'Warning');
    end
  
    % -------- Default values (CRITICAL FIX) --------
    coveragePct = 'N/A';
    coverageURL = '';

    ccDir = fullfile(baseDir, 'CodeCoverageReport');

    if exist(ccDir, 'dir')

        % ---- Extract coverage percentage ----
        try
            [~, coveragePct] = extract_coverage_from_report(ccDir);
        catch
            coveragePct = 'N/A';
        end

        % ---- Find coverage report link ----
        linkFile = dir(fullfile(ccDir, '*_Frame.html'));
        if ~isempty(linkFile)
            coverageHtml = fullfile(ccDir, linkFile(1).name);
            coverageURL  = ['<a href="file:///' ...
                            strrep(coverageHtml, '\', '/') ...
                            '" target="_blank">View</a>'];
        end
    end

    % ? ALWAYS add a module row (even for single Excel)
    modules(end+1).name             = moduleName;          %#ok<AGROW>
    modules(end).coverage_percent   = coveragePct;
    modules(end).coverage_url       = coverageURL;
end

html = inject_modules_into_coverage(html, modules);
html = regexprep(html, '\{%.*?\%\}', '');

if ~exist(reportsDir, 'dir')
    mkdir(reportsDir);
end

reportFile = fullfile(reportsDir, 'coverage.html');
fid = fopen(reportFile, 'w');
fwrite(fid, html);
fclose(fid);

end

function html = inject_modules_into_coverage(html, modules)
    fig = resolveGuiFig();
	targetBox = getappdata(fig,'targetCoverageBox');
    try
        if isempty(targetBox)
            TARGET = 80;
        else
            targetCoverage = str2double(targetBox.String);
            if isnan(targetCoverage)
                TARGET = 80;
            else
                TARGET = targetCoverage;  % percent
            end
        end
    catch
        TARGET = 80;
    end
    
    rows = '';
    reachedCount = 0;
    notReachedCount = 0;

for k = 1:numel(modules)

    m = modules(k);

    covStr = 'N/A';
    covVal = 0;

    if isfield(m,'coverage_percent') && ~isempty(m.coverage_percent)
        covStr = m.coverage_percent;
        tok = regexp(covStr,'(\d+(\.\d+)?)','tokens','once');
        if ~isempty(tok)
            covVal = str2double(tok{1});
        end
    end

    % -------- Target logic --------
    reached = covVal >= TARGET;

    if reached
        reachedCount = reachedCount + 1;
        barClass  = 'progress-bar pass';
        statusTxt = '<span class="status-reached">Target Reached</span>';
    else
        notReachedCount = notReachedCount + 1;
        barClass  = 'progress-bar';
        statusTxt = '<span class="status-not-reached">Target Not Reached</span>';
    end

    % -------- Coverage report cell --------
    if isempty(m.coverage_url)
        reportCell = '-';
    else
        reportCell = m.coverage_url;
    end
    
    m.name = strrep(m.name, '_TestCase', '');
    % -------- Build row --------
    rows = [rows ...
        '<tr>' ...
            '<td>' m.name '</td>' ...
            '<td class="coverage-cell">' ...
                '<div class="coverage-text">' covStr '</div>' ...
                '<div class="progress-container">' ...
                    '<div class="' barClass '" style="width:' num2str(min(covVal,100)) '%;"></div>' ...
                    '<div class="target-marker"></div>' ...
                '</div>' ...
            '</td>' ...
            '<td><strong>' num2str(TARGET) '</strong></td>' ...
            '<td>' reportCell '</td>' ...
            '<td>' statusTxt '</td>' ...
        '</tr>'];
end

% -------- Summary row --------
rows = [rows ...
    '<tr class="summary-row">' ...
        '<td colspan="5">' ...
            'Target Reached: ' num2str(reachedCount) ...
            ' &nbsp;&nbsp;|&nbsp;&nbsp; ' ...
            'Target Not Reached: ' num2str(notReachedCount) ...
        '</td>' ...
    '</tr>'];

html = regexprep( ...
    html, ...
    '\{% for module in modules %\}[\s\S]*?\{% endfor %\}', ...
    rows, ...
    'once');

end

function [frameName, coveragePercent] = extract_coverage_from_report(codeCoverageDir)

    frameName = '';
    coveragePercent = '';

    files = dir(fullfile(codeCoverageDir, 'Test_Frame*_Main.html'));
    if isempty(files)
        error('No Test_Frame*_Main.html found.');
    end

    htmlFile = fullfile(codeCoverageDir, files(1).name);

    fid = fopen(htmlFile, 'r');
    raw = fread(fid, '*char')';
    fclose(fid);

    % Strip HTML tags safely
    textOnly = regexprep(raw, '<[^>]*>', ' ');
    textOnly = regexprep(textOnly, '\s+', ' ');

    % Extract Test_Frame name
    tok = regexp(textOnly, '(Test_Frame_[A-Za-z0-9_]+)', 'tokens', 'once');
    if ~isempty(tok)
        frameName = tok{1};
    end

    % Extract percentage
    tok = regexp(textOnly, '(\d+(\.\d+)?\s*%)', 'tokens', 'once');
    if ~isempty(tok)
        coveragePercent = tok{1};
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
