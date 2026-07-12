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
%  File         :  generate_requirements_report.m
%
%  Description  :  Generates Requirements page in the Reports.
%
% *************************************************************************
function reportFile = generate_requirements_report(excelPaths, templatesDir, reportsDir)
 
fig = resolveGuiFig();
if nargin < 3
    error('Usage: generate_requirements_report(excelPaths, templatesDir, reportsDir)');
end
 
if ischar(excelPaths)
    excelPaths = {excelPaths};
end
 
modules = struct([]);
allReqIdsFromExcel = {};
allCoveredReqIds   = {};
 
for k = 1:numel(excelPaths)
 
    excelPath = excelPaths{k};
    [~, submodule_name, ~] = fileparts(excelPath);
    logFile   = fullfile(fileparts(excelPath), 'commandLog.txt');
    commandLog(logFile, 'Generating Requirements report for %s ...', submodule_name);
    baseDir   = fileparts(excelPath);
    [~, moduleName] = fileparts(excelPath);
 
    [folder, name, ~] = fileparts(excelPath);
    dataFolder = dir(fullfile(folder, '*_data'));
    dataFolderPath = [dataFolder.folder, '\', dataFolder.name];
    matFile = fullfile(dataFolderPath, [name '_requirements.mat']);
 
    doorsMap = containers.Map('KeyType','char','ValueType','char');
 
    excelReqMap = containers.Map('KeyType','char','ValueType','any');
    reqDescMap  = containers.Map('KeyType','char','ValueType','char');
 
    if exist(matFile,'file')
 
        data = load(matFile);
 
        if isfield(data,'req_table')
            reqData = data.req_table;
        else
            fn = fieldnames(data);
            reqData = data.(fn{1});
        end
 
        % req_table = {req_id, doors_link, description}
        for i = 1:size(reqData,1)
 
            req_id     = strtrim(reqData{i,1});
            doors_link = strtrim(reqData{i,2});
            desc       = strtrim(reqData{i,3});
 
            normId = normalize_req_id(req_id);
            if isempty(normId), continue; end
 
            % ? Fill maps (same structure as Excel earlier)
            doorsMap(normId) = doors_link;
 
            excelReqMap(normId) = struct( ...
                'orig', req_id, ...
                'desc', desc );
 
            reqDescMap(normId) = desc;
 
            allReqIdsFromExcel{end+1} = normId; %#ok<AGROW>
        end
    end
 
    [tsResults,~,tsReq,~] = runFullEvaluation(baseDir);
 
    coveredMap = containers.Map('KeyType','char','ValueType','any');
    tsKeys = keys(tsReq);
 
    for i = 1:numel(tsKeys)
 
        ts = tsKeys{i};
 
        reqList = tsReq(ts);
        if isempty(reqList), continue; end
 
        for r = 1:numel(reqList)
 
            origReqId = strtrim(reqList{r});
            normReqId = normalize_req_id(origReqId);
 
            if isempty(normReqId), continue; end
 
            allCoveredReqIds{end+1} = normReqId;
 
            if ~isKey(coveredMap, normReqId)
                coveredMap(normReqId) = struct('orig', origReqId, 'testcases', {{}} );
            end
 
            tmp = coveredMap(normReqId);
            tmp.testcases{end+1} = ts;
            coveredMap(normReqId) = tmp;
        end
    end
 
    coveredRows = struct([]);
    coveredKeys = sort(keys(coveredMap));
 
    for i = 1:numel(coveredKeys)
 
        normReqId = coveredKeys{i};
        entry = coveredMap(normReqId);
 
        tsList = entry.testcases;
 
        passCount = 0;
        failCount = 0;
        partialCount = 0;
 
        processed = containers.Map;
 
        for t = 1:numel(tsList)
 
            tsName = tsList{t};
 
            if isKey(processed, tsName)
                continue;
            end
            processed(tsName) = true;
 
            if ~isKey(tsResults, tsName)
                failCount = failCount + 1;
                continue;
            end
 
            result = tsResults(tsName);
 
            if islogical(result)
                if result
                    passCount = passCount + 1;
                else
                    failCount = failCount + 1;
                end
            else
                failCount = failCount + 1;
            end
        end
 
        totalTests = passCount + failCount + partialCount;
 
        passPercentage = 0;
        if totalTests > 0
            passPercentage = (passCount / totalTests) * 100;
        end
 
        if isKey(reqDescMap, normReqId)
            desc = reqDescMap(normReqId);
        else
            desc = '-';
        end
 
        coveredRows(i).sno             = i;
        coveredRows(i).reqid           = entry.orig;
        coveredRows(i).reqid_norm      = normReqId;
        coveredRows(i).req_description = desc;
 
        coveredRows(i).passed = passCount;
        coveredRows(i).failed = failCount;
        coveredRows(i).pass_percentage = passPercentage;
 
        coveredRows(i).testcases = strjoin(unique(tsList), ', ');
 
        coveredRows(i).doors_link = '';
        if exist('doorsMap','var') && isKey(doorsMap, normReqId)
            coveredRows(i).doors_link = doorsMap(normReqId);
        end
 
        if length(coveredRows(i).reqid) < 3
            coveredRows(i).reqid = '';
        end
    end
 
    uncoveredRows = struct([]);
    idx = 1;
 
    excelKeys = keys(excelReqMap);
 
    for i = 1:numel(excelKeys)
 
        normReqId = excelKeys{i};
 
        if ~isKey(coveredMap, normReqId)
 
            info = excelReqMap(normReqId);
 
            uncoveredRows(idx).sno = idx;
            uncoveredRows(idx).reqid = info.orig;
            uncoveredRows(idx).req_description = info.desc;
 
            uncoveredRows(idx).doors_link = '';
            if exist('doorsMap','var') && isKey(doorsMap, normReqId)
                uncoveredRows(idx).doors_link = doorsMap(normReqId);
            end
 
            idx = idx + 1;
        end
    end
 
    % STORE
    modules(k).name = moduleName;
    modules(k).requirements = coveredRows;
    modules(k).uncovered_requirements = uncoveredRows;
end
 
totalRequirements   = numel(unique(allReqIdsFromExcel));
coveredRequirements = numel(unique(allCoveredReqIds));
uncovered = totalRequirements-coveredRequirements;
if uncovered < 0
    uncovered = 0;
end
uncoveredRequirements = num2str(uncovered);
 
html = fileread(fullfile(templatesDir,'requirements_template.html'));
 
html = strrep(html,'{{ title }}','Requirements Coverage Summary');
html = strrep(html,'{{ total_requirements }}',num2str(totalRequirements));
html = strrep(html,'{{ covered_requirements }}',num2str(coveredRequirements));
html = strrep(html,'{{ uncovered_requirements }}',num2str(totalRequirements-coveredRequirements));
 
html = inject_modules_into_requirements(html, modules);
html = regexprep(html,'\{%.*?\%\}','');
 
if ~exist(reportsDir,'dir'), mkdir(reportsDir); end
 
reportFile = fullfile(reportsDir,'requirements.html');
 
fid = fopen(reportFile,'w');
fwrite(fid,html);
fclose(fid);
 
setappdata(fig, 'totalRequirements', totalRequirements);
setappdata(fig, 'coveredRequirements', coveredRequirements);
setappdata(fig, 'uncoveredRequirements', uncoveredRequirements);
 
pushWS(fig,'totalRequirements',totalRequirements);
pushWS(fig, 'coveredRequirements', coveredRequirements);
pushWS(fig, 'uncoveredRequirements', uncoveredRequirements);
end


function [tsResults, tsExec, tsReq, summary] = runFullEvaluation(baseDir)

milExpResults = run_MIL_vs_Expected(baseDir);
milSilResults = run_MIL_vs_SIL(baseDir);

% Convert to maps for fast lookup
milExpMap = containers.Map;
milSilMap = containers.Map;

for i = 1:numel(milExpResults)
    milExpMap(milExpResults(i).testcase) = milExpResults(i).status;
end

for i = 1:numel(milSilResults)
    milSilMap(milSilResults(i).testcase) = milSilResults(i).status;
end

listing = dir(fullfile(baseDir, 'TS_*'));

tsResults = containers.Map;
tsExec    = containers.Map;
tsReq     = containers.Map;

for i = 1:numel(listing)

    tsName = listing(i).name;
    tsPath = fullfile(baseDir, tsName);
    pass = false;

    if isKey(milExpMap, tsName) && isKey(milSilMap, tsName)

        milExpPass = strcmpi(milExpMap(tsName), 'PASS');
        milSilPass = strcmpi(milSilMap(tsName), 'PASS');

        pass = milExpPass && milSilPass;
    end

    execTime = NaN;
    expFile = dir(fullfile(tsPath, '*_expected_output.mat'));
    if ~isempty(expFile)
        d = load(fullfile(tsPath, expFile(1).name));
        if isfield(d, 't')
            execTime = d.t(end);
        end
    end
    
    reqFile = dir(fullfile(tsPath, '*_requirements.txt'));
    reqs = {};

    if ~isempty(reqFile)
        fid = fopen(fullfile(tsPath, reqFile(1).name));
        c = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);

        reqs = strtrim(c{1});
        reqs = reqs(~cellfun('isempty', reqs));
    end

    % ? Debug: detect missing mapping
    if ~pass && isempty(reqs)
        fprintf('WARNING: FAILED test %s has NO requirement mapping!\n', tsName);
    end

    tsResults(tsName) = pass;
    tsExec(tsName)    = execTime;
    tsReq(tsName)     = reqs;
end

vals = cell2mat(values(tsResults));

summary.total  = numel(vals);
summary.passed = sum(vals);
summary.failed = summary.total - summary.passed;

fprintf('\n===== FINAL TEST STATUS =====\n');
k = keys(tsResults);

for i = 1:length(k)
    fprintf('%s ? %d\n', k{i}, tsResults(k{i}));
end

fprintf('============================\n\n');

end

function tolerances = loadTolerances(baseDir)

% ---------------- FIND *_data DIRECTORY ----------------
d = dir(fullfile(baseDir, '*_data'));
if isempty(d)
    error('No *_data directory found for tolerances.');
end

dataFolder = fullfile(baseDir, d(1).name);

% ---------------- LOAD MAT FILE ----------------
tolFile = fullfile(dataFolder, 'back2back_tolerances.mat');
if ~exist(tolFile, 'file')
    error('Tolerance file not found: %s', tolFile);
end

matData = load(tolFile);
fields = fieldnames(matData);

tolerances = containers.Map;

for i = 1:numel(fields)
    % Take first element as tolerance
    tolerances(fields{i}) = matData.(fields{i})(1);
end

end

function [tsPass, execTime, requirements] = processTSFolder(tsPath, tolerances)

files = dir(tsPath);

milFile = '';
silFile = '';
expFile = '';
reqFile = '';

% ---------------- FIND FILES ----------------
for i = 1:numel(files)
    n = files(i).name;

    if endsWith(n, '_mil.mat')
        milFile = fullfile(tsPath, n);
    elseif endsWith(n, '_sil.mat')
        silFile = fullfile(tsPath, n);
    elseif endsWith(n, '_expected_output.mat')
        expFile = fullfile(tsPath, n);
    elseif endsWith(n, '_requirements.txt')
        reqFile = fullfile(tsPath, n);
    end
end

% ---------------- VALIDATION ----------------
if isempty(milFile) || isempty(silFile) || isempty(expFile)
    tsPass = [];
    execTime = [];
    requirements = {};
    return;
end

% ---------------- EXECUTION TIME ----------------
execTime = NaN;
d = load(expFile);
if isfield(d, 't')
    execTime = d.t(end);
end

% ---------------- REQUIREMENTS ----------------
requirements = {};

if ~isempty(reqFile)
    fid = fopen(reqFile);
    c = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);

    requirements = strtrim(c{1});
    requirements = requirements(~cellfun('isempty', requirements));
end

% ---------------- LOAD DATA ----------------
milData = load(milFile);
silData = load(silFile);
expData = load(expFile);

vars = fieldnames(milData);

mil_exp_results = [];
mil_sil_results = [];

for i = 1:numel(vars)

    if ~endsWith(vars{i}, '_mil')
        continue;
    end

    base = vars{i}(1:end-4);
    expVar = [base '_exp'];

    if ~isKey(tolerances, base) || ~isfield(expData, expVar)
        continue;
    end

    diff = abs(milData.(vars{i})(:) - expData.(expVar)(:));
    mil_exp_results(end+1) = all(diff <= tolerances(base)); %#ok<AGROW>
end

for i = 1:numel(vars)

    if ~endsWith(vars{i}, '_mil')
        continue;
    end

    base = vars{i}(1:end-4);
    silVar = [base '_sil'];

    if ~isKey(tolerances, base) || ~isfield(silData, silVar)
        continue;
    end

    diff = abs(milData.(vars{i})(:) - silData.(silVar)(:));
    mil_sil_results(end+1) = all(diff <= tolerances(base)); %#ok<AGROW>
end

if isempty(mil_exp_results)
    mil_exp_pass = false;
else
    mil_exp_pass = all(mil_exp_results);
end

if isempty(mil_sil_results)
    mil_sil_pass = false;
else
    mil_sil_pass = all(mil_sil_results);
end

tsPass = mil_exp_pass && mil_sil_pass;

fprintf('TS: %s | MIL-EXP: %d | MIL-SIL: %d | FINAL: %d\n', ...
    tsPath, mil_exp_pass, mil_sil_pass, tsPass);

end

function html = inject_modules_into_requirements(html, modules)

block = '';
summaryRows = '';

for k = 1:numel(modules)

    m = modules(k);
    modId = upper(regexprep(m.name,'[^a-zA-Z0-9]','_'));

    % ? Navigation links
    coveredLink   = ['<a href="#' modId '_COVERED">View</a>'];
    
    if isempty(m.uncovered_requirements)
        uncoveredLink = '-';
    else
        uncoveredLink = ['<a href="#' modId '_UNCOVERED">View</a>'];
    end
    m.name = strrep(m.name, '_TestCase', '');
    
    summaryRows = [summaryRows ...
        '<tr>' ...
        '<td>' m.name '</td>' ...
        '<td>' coveredLink '</td>' ...
        '<td>' uncoveredLink '</td>' ...
        '</tr>'];

    % MODULE CARD
    block = [block ...
        '<div class=card>' ...
        '<div><b>Module: ' m.name '</b></div>'];

    % COVERED TABLE
    block = [block ...
        '<h3 id=' modId '_COVERED>Covered Requirements</h3>' ...
        '<table class=covered-table>' ...
        '<tr>' ...
        '<th>S. No</th><th style="width: 80px;">Req ID</th><th style="width: 900px;">Description</th>' ...
        '<th style="width: 80px;">Pass</th><th style="width: 80px;">Fail</th><th style="width: 150px;">Testcases</th>' ...
        '</tr>'];

    for i = 1:numel(m.requirements)

        r = m.requirements(i);
        if isempty(r.reqid), continue; end

        reqDisplay = r.reqid;

        % ? DOORS LINK
        if isfield(r,'doors_link') && ~isempty(r.doors_link)
            reqDisplay = ['<a href="',r.doors_link,'">', r.reqid '</a>'];
        end

        block = [block ...
            '<tr id=' r.reqid_norm '>' ...
            '<td>' num2str(r.sno) '</td>' ...
            '<td>' reqDisplay '</td>' ...
            '<td>' r.req_description '</td>' ...
            '<td class=status-pass>' num2str(r.passed) '</td>' ...
            '<td class=status-fail>' num2str(r.failed) '</td>' ...
            '<td>' r.testcases '</td>' ...
            '</tr>'];
    end

    block = [block '</table>'];

    % UNCOVERED TABLE
    if ~isempty(m.uncovered_requirements)

        block = [block ...
            '<h3 id=' modId '_UNCOVERED>Uncovered Requirements</h3>' ...
            '<table class=uncovered-table>' ...
            '<tr><th>S. No</th><th>Req ID</th><th>Description</th></tr>'];

        for i = 1:numel(m.uncovered_requirements)

            r = m.uncovered_requirements(i);

            reqDisplay = r.reqid;

            if isfield(r,'doors_link') && ~isempty(r.doors_link)
                reqDisplay = ['<a href="',r.doors_link,'">', r.reqid '</a>'];
            end

            block = [block ...
                '<tr>' ...
                '<td>' num2str(r.sno) '</td>' ...
                '<td>' reqDisplay '</td>' ...
                '<td>' r.req_description '</td>' ...
                '</tr>'];
        end

        block = [block '</table>'];
    end

    block = [block '</div>'];

end

html = strrep(html,'{{ module_summary_rows }}', summaryRows);

html = regexprep(html, ...
    '\{% for module in modules %\}[\s\S]*?\{% endfor %\}', ...
    block, 'once');

end

function out = normalize_req_id(in)
if isempty(in)
    out = '';
else
    out = upper(regexprep(strtrim(in),'[_-]',''));
end
end

function out = tern(cond,a,b)
if cond, out = a; else, out = b; end
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
        results(end+1) = struct('testcase', tsName, 'status', 'FAIL'); %#ok<AGROW>
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
        results(end+1) = struct('testcase', tsName, 'status', 'FAIL'); %#ok<AGROW>
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