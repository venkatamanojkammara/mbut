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
%  File         :  generate_consolidated_report.m
%
%  Description  :  Generates consolidated report, incase of multiple SUTs.
%
% *************************************************************************
function reportFile = generate_consolidated_report(basePaths, outputBasePath)

    if ischar(basePaths)
        basePaths = {basePaths};
    end

    % LOAD TEMPLATE 
    tmplPath = fullfile(fileparts(mfilename('fullpath')), 'consilidated_template.html');
    escapedHtml = fileread(tmplPath);

    % DECODE ESCAPED HTML 
    html = escapedHtml;
    html = strrep(html, '&lt;', '<');
    html = strrep(html, '&gt;', '>');
    html = strrep(html, '&amp;', '&');

    % LOCATE CONTAINER 
    containerStartTag = '<div class="container">';
    containerEndTag   = '</div>';

    startIdx = strfind(html, containerStartTag);
    endIdx   = strfind(html, containerEndTag);

    if isempty(startIdx) || isempty(endIdx)
        error('Container block not found after decoding template.html');
    end

    containerStart = startIdx(1);
    containerEnd   = endIdx(find(endIdx > containerStart, 1, 'last')) ...
                     + length(containerEndTag) - 1;

    headerHtml    = html(1:containerStart-1);
    containerHtml = html(containerStart:containerEnd);
    footerHtml    = html(containerEnd+1:end);

    allSections = '';

    % PROCESS EACH BASE PATH 
    for k = 1:numel(basePaths)

        baseDir = fileparts(basePaths{k});

        [tsResults, tsExec, tsReq, summary] = runFullEvaluation(baseDir);

        sectionHtml = containerHtml;

        %%  BASIC TEXT 
        sectionHtml = strrep(sectionHtml,'{{ title }}', ...
            sprintf('Test Case Report – Set %d', k));

        sectionHtml = strrep(sectionHtml,'{{ description }}', baseDir);
        sectionHtml = strrep(sectionHtml,'{{ total }}',  num2str(summary.total));
        sectionHtml = strrep(sectionHtml,'{{ passed }}', num2str(summary.passed));
        sectionHtml = strrep(sectionHtml,'{{ failed }}', num2str(summary.failed));

        %%  TABLE HEADER 
        cols = {'Test Case','Status','Execution Time (ms)','Requirements'};
        th = '';
        for i = 1:numel(cols)
            th = [th '<th>' cols{i} '</th>']; %#ok<AGROW>
        end

        sectionHtml = regexprep(sectionHtml, ...
            '\{% for col in table_columns %\}.*?\{% endfor %\}', ...
            th, 'dotall');


        rows = '';
        tsKeys = keys(tsResults);

        for i = 1:numel(tsKeys)
            ts = tsKeys{i};

            if tsResults(ts)
                status = '<td class="status-pass">PASS</td>';
            else
                status = '<td class="status-fail">FAIL</td>';
            end

            execMs = tsExec(ts) * 1000;

            reqs = tsReq(ts);
            if isempty(reqs)
                reqTxt = '-';
            else
                reqTxt = strjoin(reqs, ', ');
            end

            rows = [rows ...
                '<tr>' ...
                '<td>' ts '</td>' ...
                status ...
                '<td>' num2str(execMs) '</td>' ...
                '<td>' reqTxt '</td>' ...
                '</tr>'];
        end

        sectionHtml = regexprep(sectionHtml, ...
            '\{% for row in table_data %\}.*?\{% endfor %\}', ...
            rows, 'dotall');

        sectionHtml = strrep(sectionHtml, ...
            'id="pieChart"', ['id="pieChart_' num2str(k) '"']);

        sectionHtml = strrep(sectionHtml, ...
            'getElementById(''pieChart'')', ...
            ['getElementById(''pieChart_' num2str(k) ''')']);

        sectionHtml = strrep(sectionHtml, ...
            '{{ labels | tojson }}', '["Passed","Failed"]');

        sectionHtml = strrep(sectionHtml, ...
            '{{ values | tojson }}', ...
            ['[' num2str(summary.passed) ',' num2str(summary.failed) ']']);

        sectionHtml = regexprep(sectionHtml, '\{%.*?\%\}', '');

        allSections = [allSections sectionHtml newline]; %#ok<AGROW>
    end

    % FINAL HTML 
    finalHtml = [headerHtml allSections footerHtml];

    % OUTPUT DIRECTORY 
    reportRoot = fullfile(outputBasePath, 'BatchRun Reports');
    if ~exist(reportRoot, 'dir')
        mkdir(reportRoot);
    end

    reportFile = fullfile(reportRoot, 'consolidated_report.html');

    fid = fopen(reportFile, 'w');
    fwrite(fid, finalHtml);
    fclose(fid);

    disp('? Consolidated report generated successfully');
    disp(['? Report saved at: ' reportFile]);

    % OPEN AUTOMATICALLY 
    web(reportFile, '-browser');

end

function [tsResults, tsExec, tsReq, summary] = runFullEvaluation(baseDir)

    tolerances = loadTolerances(baseDir);
    listing = dir(fullfile(baseDir,'TS_*'));

    tsResults = containers.Map;
    tsExec    = containers.Map;
    tsReq     = containers.Map;

    for i = 1:numel(listing)
        tsPath = fullfile(baseDir, listing(i).name);
        [pass, execTime, reqs] = processTSFolder(tsPath, tolerances);

        if ~isempty(pass)
            tsResults(listing(i).name) = pass;
            tsExec(listing(i).name)    = execTime;
            tsReq(listing(i).name)     = reqs;
        end
    end

    vals = cell2mat(values(tsResults));
    summary.total  = numel(vals);
    summary.passed = sum(vals);
    summary.failed = summary.total - summary.passed;

end

function tolerances = loadTolerances(baseDir)

    d = dir(fullfile(baseDir,'*_data'));
    dataFolder = fullfile(baseDir, d(1).name);

    matData = load(fullfile(dataFolder,'back2back_tolerances.mat'));
    f = fieldnames(matData);

    tolerances = containers.Map;
    for i = 1:numel(f)
        tolerances(f{i}) = matData.(f{i})(1);
    end

end

function [tsPass, execTime, requirements] = processTSFolder(tsPath, tolerances)

    files = dir(tsPath);
    milFile=''; silFile=''; expFile=''; reqFile='';

    for i = 1:numel(files)
        n = files(i).name;
        if endsWith(n,'_mil.mat'), milFile = fullfile(tsPath,n); end
        if endsWith(n,'_sil.mat'), silFile = fullfile(tsPath,n); end
        if endsWith(n,'_expected_output.mat'), expFile = fullfile(tsPath,n); end
        if endsWith(n,'_requirements.txt'), reqFile = fullfile(tsPath,n); end
    end

    if isempty(milFile) || isempty(silFile)
        tsPass=[]; execTime=[]; requirements={};
        return;
    end

    execTime = NaN;
    if ~isempty(expFile)
        d = load(expFile);
        if isfield(d,'t'), execTime = d.t(end); end
    end

    requirements = {};
    if ~isempty(reqFile)
        fid=fopen(reqFile);
        c=textscan(fid,'%s','Delimiter','\n');
        fclose(fid);
        requirements=c{1};
    end

    milData = load(milFile);
    silData = load(silFile);

    vars = fieldnames(milData);
    results = [];

    for i = 1:numel(vars)
        if ~endsWith(vars{i},'_mil'), continue; end
        base = vars{i}(1:end-4);

        if ~isKey(tolerances,base), continue; end
        silVar = [base '_sil'];
        if ~isfield(silData,silVar), continue; end

        diff = abs(milData.(vars{i})(:) - silData.(silVar)(:));
        results(end+1) = all(diff <= tolerances(base)); 
    end

    if isempty(results)
        tsPass = false;
    else
        tsPass = all(results);
    end

end