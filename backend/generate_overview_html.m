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
%  File         :  generate_overview_html.m
%
%  Description  :  Generates Overview page in the Reports.
%
% *************************************************************************
function reportFile = generate_overview_html(excelPaths, templatesDir, reportsDir)

    fig = resolveGuiFig();

    totalRequirements   = getappdata(fig, 'totalRequirements');
    coveredRequirements = getappdata(fig, 'coveredRequirements');
    uncoveredRequirements = getappdata(fig, 'uncoveredRequirements');

    if nargin < 3
        error('Usage: generate_overview_html(excelPaths, templatesDir, reportsDir)');
    end

    % Normalize input
    if ischar(excelPaths)
        excelPaths = {excelPaths};
    end

    modules = struct([]);
    total  = 0;
    passed = 0;
    failed = 0;

    for k = 1:numel(excelPaths)

    excelPath = excelPaths{k};
    baseDir   = fileparts(excelPath);
    [~, moduleName] = fileparts(excelPath);
    
    [~, submodule_name, ~] = fileparts(excelPath);
    submodule_name = strrep(submodule_name, '_TestCase', '');
    logFile   = fullfile(fileparts(excelPath), 'commandLog.txt');
    commandLog(logFile, 'Generating Coverage report for %s ...', submodule_name);

    [~, tsExec, tsReq, ~] = runFullEvaluation(baseDir);

    milVsExpected = run_MIL_vs_Expected(baseDir);
    milVsSIL      = run_MIL_vs_SIL(baseDir);

    % Maps
    milExpMap = containers.Map;
    for i = 1:numel(milVsExpected)
        milExpMap(milVsExpected(i).testcase) = milVsExpected(i).status;
    end

    milSilMap = containers.Map;
    for i = 1:numel(milVsSIL)
        milSilMap(milVsSIL(i).testcase) = milVsSIL(i).status;
    end

    tsKeys = keys(tsExec);
    
    testCaseIDMap = getappdata(fig, 'testCaseMap');
    tsNames = keys(testCaseIDMap);
    tsIDs = values(testCaseIDMap);
    tc = struct([]);

    for i = 1:numel(tsKeys)

        ts = tsKeys{i};
        valToFind = ts;

        idx = strcmp(tsIDs, valToFind);

        if any(idx)
            ts_name = tsNames{find(idx,1)};
        else
            ts_name = ts;
        end
        % -------- Status --------
        milExpStatus = 'FAIL';
        milSilStatus = 'FAIL';

        if isKey(milExpMap, ts)
            milExpStatus = milExpMap(ts);
        end

        if isKey(milSilMap, ts)
            milSilStatus = milSilMap(ts);
        end

        if strcmp(milExpStatus,'PASS') && strcmp(milSilStatus,'PASS')
            status = 'PASS';
            passed = passed + 1;
        else
            status = 'FAIL';
            failed = failed + 1;
        end

        total = total + 1;

        % -------- Execution Time --------
        execSec = tsExec(ts);

        % -------- Description --------
        desc = read_txt(baseDir, ts, '_description.txt');

        % -------- Requirements links --------
        reqHtml = '-';
        if isKey(tsReq, ts) && ~isempty(tsReq(ts))

            reqIds = tsReq(ts);
            links = cell(1,numel(reqIds));

            for r = 1:numel(reqIds)

                orig = strtrim(reqIds{r});
                norm = normalize_req_id(orig);

                links{r} = ['<a href="requirements.html#' norm ...
                            '" target="_self">' orig '</a>'];
            end

            reqHtml = strjoin(links, ', ');
        end

        % -------- Other Fields --------
        testSpec = read_txt(baseDir, ts, '_test_specification.txt');
        preCond  = read_txt(baseDir, ts, '_preconditions.txt');
        passCond = read_txt(baseDir, ts, '_pass_conditions.txt');

        % -------- Store --------
        tc(i).testcase           = ts;
        tc(i).testcase_name      = ts_name;
        tc(i).exec_time          = sprintf('%.2f', execSec);
        tc(i).status             = status;
        tc(i).description        = desc;
        tc(i).requirements       = reqHtml;
        tc(i).test_specification = testSpec;
        tc(i).preconditions      = preCond;
        tc(i).pass_conditions    = passCond;
    end

    modules(k).name            = moduleName;
    modules(k).testcases       = tc;
    modules(k).mil_vs_expected = milVsExpected;
    modules(k).mil_vs_sil      = milVsSIL;
    end

    totalReq     = totalRequirements;
    coveredReq   = coveredRequirements;
    uncoveredReq = uncoveredRequirements;
    total_execution_time = string(getappdata(fig, 'total_execution_time'));
    if isempty(total_execution_time)
        total_execution_time = 0;
    end


    html = fileread(fullfile(templatesDir,'overview_template.html'));
    html = strrep(html,'{{ title }}','Test Case Report');
    html = strrep(html,'{{ description }}','MIL & SIL Validation');
    html = strrep(html,'{{ total }}',num2str(total));
    html = strrep(html,'{{ passed }}',num2str(passed));
    html = strrep(html,'{{ failed }}',num2str(failed));
    html = strrep(html,'{{ matlab_version }}',version('-release'));
    html = strrep(html,'{{ tool_version }}','v0.1');
    html = strrep(html,'{{ model_version }}','1.29230');
    html = strrep(html,'{{ report_created_on }}',datestr(now,'dd-mm-yyyy HH:MM:SS'));
    html = strrep(html,'{{ total_execution_time }}',total_execution_time);
    % -------- Test Case Pie --------
    html = strrep(html,'{{ labels | tojson }}','[''Passed'',''Failed'']');
    html = strrep(html,'{{ values | tojson }}', ...
        ['[' num2str(passed) ',' num2str(failed) ']']);

    % -------- Requirement Pie --------
    html = strrep(html,'{{ req_labels | tojson }}','[''Covered'',''Uncovered'']');
    html = strrep(html,'{{ req_values | tojson }}', ...
        ['[' num2str(coveredReq) ',' num2str(uncoveredReq) ']']);
    html = strrep(html,'{{ req_total }}', num2str(totalReq));
    html = strrep(html,'{{ req_covered }}', num2str(coveredReq));
    html = strrep(html,'{{ req_uncovered }}', num2str(uncoveredReq));
	
	% -------- Module Navigation --------
	navRows = '';

	for k = 1:numel(modules)

		modId = upper(regexprep(modules(k).name,'[^a-zA-Z0-9]','_'));
		module_name = strrep(modules(k).name,'_TestCase','');

		navRows = [navRows ...
			'<tr>' ...
			'<td>' module_name '</td>' ...
			'<td> <a href="#'modId '">View</a></td>' ...
			'</tr>'];
	end

	html = strrep(html, '{{ module_navigation_rows }}', navRows);

    % -------- Inject Modules --------
    html = inject_modules_into_overview(html, modules);

    % Cleanup template tags
    html = regexprep(html,'\{%.*?\%\}','');

    if ~exist(reportsDir,'dir'), mkdir(reportsDir); end
    reportFile = fullfile(reportsDir,'overview.html');

    fid = fopen(reportFile,'w');
    fwrite(fid,html);
    fclose(fid);

    % Generate failure drill-down pages
    generate_failed_details_report(excelPaths, templatesDir, reportsDir);

end

function out = normalize_req_id(in)
    if isempty(in)
        out = '';
    else
        out = upper(regexprep(strtrim(in),'[_-]',''));
        if length(out) < 3
            out = '';
        end
    end
end

function html = inject_modules_into_overview(html, modules)
    block = '';

for k = 1:numel(modules)

    m = modules(k);
    module_name = strrep(m.name, '_TestCase', '');

    % ================= MODULE CARD =================
	modId = upper(regexprep(m.name,'[^a-zA-Z0-9]','_'));

	block = [block ...
		'<div class="card" id="' modId '">' ...
		'<h2>Module: ' module_name '</h2>'];

    block = [block ...
        '<h3>Test Case Results</h3>' ...
        '<table>' ...
        '<tr>' ...
            '<th style="width: 80px;">Test Case ID</th>' ...
            '<th style="width: 150px;">Test Case Name</th>' ...
            '<th style="width: 80px;">Execution Time (sec)</th>' ...
            '<th style="width: 80px;">Status</th>' ...
            '<th style="width: 150px;">Description</th>' ...
            '<th style="width: 80px;">Requirements</th>' ...
            '<th style="width: 150px;">Test Specification</th>' ...
            '<th style="width: 200px;">Preconditions</th>' ...
            '<th style="width: 150px;">Pass Conditions</th>' ...
        '</tr>'];

    for i = 1:numel(m.testcases)
        r = m.testcases(i);

        if strcmp(r.status,'PASS')
            status_html = '<span class="status-pass">PASS</span>';
        else
            % status_html = ['</a>' r.testcase '_failed.html>FAIL</a>'];
            status_html = ['<a href="', module_name, '_', r.testcase '_failed.html"> FAIL </a>'];
        end

        block = [block ...
            '<tr>' ...
                '<td>' r.testcase '</td>' ...
                '<td>' r.testcase_name '</td>' ...
                '<td>' r.exec_time '</td>' ...
                '<td>' status_html '</td>' ...
                '<td>' r.description '</td>' ...
                '<td>' r.requirements '</td>' ...
                '<td>' r.test_specification '</td>' ...
                '<td>' r.preconditions '</td>' ...
                '<td>' r.pass_conditions '</td>' ...
            '</tr>'];
    end

    block = [block '</table>'];
    
    block = [block ...
        '<h3>MIL</h3>' ...
        '<table>' ...
        '<tr>' ...
            '<th>Test Case Name</th>' ...
            '<th>Status</th>' ...
        '</tr>'];

    for i = 1:numel(m.mil_vs_expected)
        r = m.mil_vs_expected(i);
        cls = 'status-fail';
        if strcmp(r.status,'PASS')
            cls = 'status-pass';
        end

        block = [block ...
            '<tr>' ...
                '<td>' r.testcase '</td>' ...
                '<td class="' cls '">' r.status '</td>' ...
            '</tr>'];
    end

    block = [block '</table>'];

    block = [block ...
        '<h3>SIL</h3>' ...
        '<table>' ...
        '<tr>' ...
            '<th>Test Case Name</th>' ...
            '<th>Status</th>' ...
        '</tr>'];

    for i = 1:numel(m.mil_vs_sil)
        r = m.mil_vs_sil(i);
        cls = 'status-fail';
        if strcmp(r.status,'PASS')
            cls = 'status-pass';
        end

        block = [block ...
            '<tr>' ...
                '<td>' r.testcase '</td>' ...
                '<td class="' cls '">' r.status '</td>' ...
            '</tr>'];
    end

    block = [block '</table>'];

    % ================= CLOSE MODULE CARD =================
    block = [block '</div>'];
end

html = regexprep( ...
    html, ...
    '\{% for module in modules %\}[\s\S]*?\{% endfor %\}', ...
    block, ...
    'once');

end

function results = run_MIL_vs_Expected(baseDir)
tsDirs = dir(fullfile(baseDir, 'TS_*'));
tsDirs = tsDirs([tsDirs.isdir]);
results = struct('testcase', {}, 'status', {});

for k = 1:numel(tsDirs)
    tsName = tsDirs(k).name;
    tsPath = fullfile(baseDir, tsName);

    expFile = fullfile(tsPath, [tsName '_expected_output.mat']);
    milFile = fullfile(tsPath, [tsName '_output_data_mil.mat']);

    if exist(expFile, 'file') ~= 2 || exist(milFile, 'file') ~= 2
        % results(end+1) = struct('testcase', tsName, 'status', 'FAIL'); %#ok<AGROW>
        continue;
    end

    expData = load(expFile);
    milData = load(milFile);
    vars = fieldnames(expData);
    vars(strcmp(vars, 't')) = [];

    passAll = true;

    for i = 1:numel(vars)
        if ~istable(expData.(vars{i})), continue; end
        milVar = [vars{i} '_mil'];
        if ~isfield(milData, milVar)
            passAll = false; break;
        end

        expTbl = expData.(vars{i});
        expVals = table_col_to_double(expTbl, 'value');
        tolVals = table_col_to_double(expTbl, 'tolerance');

        enVals = table_col_to_double(expTbl, 'is_enable');
        if isempty(enVals)
            enVals = true(size(expVals));
        end
        enVals = logical(enVals);

        expVals = expVals(2:end);
        tolVals = tolVals(2:end);
        enVals  = enVals(2:end);

        milVals = to_vector(milData.(milVar));
        milVals = milVals(2:end);

        idx = find(enVals);
        if any(abs(milVals(idx) - expVals(idx)) > tolVals(idx))
            passAll = false; break;
        end
    end

    results(end+1) = struct('testcase', tsName, 'status', tern(passAll, 'PASS', 'FAIL')); %#ok<AGROW>
end
end

function results = run_MIL_vs_SIL(baseDir)
tsDirs = dir(fullfile(baseDir, 'TS_*'));
tsDirs = tsDirs([tsDirs.isdir]);
results = struct('testcase', {}, 'status', {});

for k = 1:numel(tsDirs)
    tsName = tsDirs(k).name;
    tsPath = fullfile(baseDir, tsName);

    mil = dir(fullfile(tsPath, '*_mil.mat'));
    sil = dir(fullfile(tsPath, '*_sil.mat'));
    exp = dir(fullfile(tsPath, '*_expected_output.mat'));

    if isempty(mil) || isempty(sil) || isempty(exp)
        % results(end+1) = struct('testcase', tsName, 'status', 'FAIL'); %#ok<AGROW>
        continue;
    end

    milData = load(fullfile(tsPath, mil(1).name));
    silData = load(fullfile(tsPath, sil(1).name));
    expData = load(fullfile(tsPath, exp(1).name));

    vars = fieldnames(expData);
    vars(strcmp(vars, 't')) = [];
    passAll = true;

    for i = 1:numel(vars)
        if ~istable(expData.(vars{i})), continue; end
        milVar = [vars{i} '_mil'];
        silVar = [vars{i} '_sil'];

        if ~isfield(milData, milVar) || ~isfield(silData, silVar)
            passAll = false; break;
        end

        expTbl = expData.(vars{i});
        tolVals = table_col_to_double(expTbl, 'tolerance');
        enVals  = table_col_to_double(expTbl, 'is_enable');

        if isempty(enVals)
            enVals = true(size(tolVals));
        end
        enVals = logical(enVals);

        tolVals = tolVals(2:end);
        enVals  = enVals(2:end);

        milVals = to_vector(milData.(milVar)); milVals = milVals(2:end);
        silVals = to_vector(silData.(silVar)); silVals = silVals(2:end);

        idx = find(enVals);
        if any(abs(milVals(idx) - silVals(idx)) > tolVals(idx))
            passAll = false; break;
        end
    end

    results(end+1) = struct('testcase', tsName, 'status', tern(passAll, 'PASS', 'FAIL')); %#ok<AGROW>
end
end

function [tsResults, tsExec, tsReq, summary] = runFullEvaluation(baseDir)
tolerances = loadTolerances(baseDir);
listing = dir(fullfile(baseDir, 'TS_*'));

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
d = dir(fullfile(baseDir, '*_data'));
dataFolder = fullfile(baseDir, d(1).name);
matData = load(fullfile(dataFolder, 'back2back_tolerances.mat'));

fields = fieldnames(matData);
tolerances = containers.Map;
for i = 1:numel(fields)
    tolerances(fields{i}) = matData.(fields{i})(1);
end
end

function [tsPass, execTime, requirements] = processTSFolder(tsPath, tolerances)
files = dir(tsPath);
milFile=''; silFile=''; expFile=''; reqFile='';

for i=1:numel(files)
    n = files(i).name;
    if endsWith(n,'_mil.mat'), milFile = fullfile(tsPath,n); end
    if endsWith(n,'_sil.mat'), silFile = fullfile(tsPath,n); end
    if endsWith(n,'_expected_output.mat'), expFile = fullfile(tsPath,n); end
    if endsWith(n,'_requirements.txt'), reqFile = fullfile(tsPath,n); end
end

if isempty(milFile) || isempty(silFile)
    tsPass = []; execTime = []; requirements = {}; return;
end

execTime = NaN;
if ~isempty(expFile)
    d = load(expFile);
    if isfield(d,'t'), execTime = d.t(end); end
end

requirements = {};
if ~isempty(reqFile)
    fid = fopen(reqFile);
    c = textscan(fid,'%s','Delimiter','\n');
    fclose(fid);
    requirements = c{1};
end

milData = load(milFile);
silData = load(silFile);
vars = fieldnames(milData);
results = [];

for i = 1:numel(vars)
    if ~endsWith(vars{i},'_mil'), continue; end
    base = vars{i}(1:end-4);
    if ~isKey(tolerances,base), continue; end

    diff = abs(milData.(vars{i})(:) - silData.([base '_sil'])(:));
    results(end+1) = all(diff <= tolerances(base)); %#ok<AGROW>
end

tsPass = all(results);
end

function v = table_col_to_double(tbl, colName)
if ~ismember(colName, tbl.Properties.VariableNames)
    v = [];
    return;
end

col = tbl.(colName);
if isnumeric(col) || islogical(col)
    v = double(col(:));
elseif iscell(col)
    v = nan(numel(col),1);
    for i=1:numel(col)
        if isnumeric(col{i}) || islogical(col{i})
            v(i) = double(col{i});
        end
    end
else
    v = [];
end
end

function v = to_vector(x)
if isnumeric(x) || islogical(x)
    v = double(x(:));
elseif istable(x)
    v = table_col_to_double(x,'value');
elseif iscell(x)
    v = nan(numel(x),1);
    for i=1:numel(x)
        if isnumeric(x{i})
            v(i) = double(x{i});
        end
    end
else
    v = [];
end
end

function out = tern(cond,a,b)
if cond, out = a; else, out = b; end
end

function out = read_txt(baseDir, ts, suffix)
out = '-';
f = fullfile(baseDir, ts, [ts suffix]);

if exist(f,'file')
    fid = fopen(f);
    c = textscan(fid,'%s','Delimiter','\n');
    fclose(fid);
    if ~isempty(c{1})
        out = strjoin(c{1},' ');
    end
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