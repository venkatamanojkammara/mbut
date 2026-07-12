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
%  File         :  generate_failed_details_report.m
%
%  Description  :  Generates Failed Test Case Details in a HTML page.
%
% *************************************************************************
function generate_failed_details_report(excelPaths, templatesDir, reportsDir)

    if ischar(excelPaths)
        excelPaths = {excelPaths};
    end

    template = fileread(fullfile(templatesDir,'failed_details_template.html'));

    if ~exist(reportsDir,'dir')
        mkdir(reportsDir);
    end

    for m = 1:numel(excelPaths)

        baseDir = fileparts(excelPaths{m});
        [~, name, ~] = fileparts(baseDir);
        moduleName =  strrep(name, 'Test_', '');
        milVsExpected = run_MIL_vs_Expected(baseDir);
        milVsSIL      = run_MIL_vs_SIL(baseDir);

        expMap = containers.Map;
        for i=1:numel(milVsExpected)
            expMap(milVsExpected(i).testcase)=milVsExpected(i).status;
        end

        silMap = containers.Map;
        for i=1:numel(milVsSIL)
            silMap(milVsSIL(i).testcase)=milVsSIL(i).status;
        end

        listing = dir(fullfile(baseDir,'TS_*'));

        for i = 1:numel(listing)

            ts = listing(i).name;
            tsPath = fullfile(baseDir,ts);

            failExp = isKey(expMap,ts)&&strcmp(expMap(ts),'FAIL');
            failSil = isKey(silMap,ts)&&strcmp(silMap(ts),'FAIL');

            if ~(failExp || failSil)
                continue;
            end

            files = dir(tsPath);
            milFile=''; silFile=''; expFile='';

            for j=1:numel(files)
                f=files(j).name;
                if endsWith(f,'_mil.mat'), milFile=fullfile(tsPath,f); end
                if endsWith(f,'_sil.mat'), silFile=fullfile(tsPath,f); end
                if endsWith(f,'_expected_output.mat'), expFile=fullfile(tsPath,f); end
            end

            rowsExp=''; rowsSil='';

            % ===== MIL vs Expected =====
            if failExp && ~isempty(milFile) && ~isempty(expFile)

                failedExp = extract_failed_mil_vs_expected(milFile, expFile);

                for k=1:numel(failedExp)
                    r = failedExp(k);

                    rowsExp = [rowsExp ...
                        '<tr>' ...
                        '<td>' num2str(k) '</td>' ...
                        '<td>' num2str(r.time,'%.4f') '</td>' ...
                        '<td>' r.signal '</td>' ...
                        '<td>' num2str(r.expected) '</td>' ...
                        '<td>' num2str(r.actual) '</td>' ...
                        '</tr>'];
                end
            end

            % ===== MIL vs SIL =====
            if failSil && ~isempty(milFile) && ~isempty(silFile) && ~isempty(expFile)

                failedSil = extract_failed_mil_vs_sil(milFile, silFile, expFile);

                for k=1:numel(failedSil)
                    r = failedSil(k);

                    rowsSil = [rowsSil ...
                        '<tr>' ...
                        '<td>' num2str(k) '</td>' ...
                        '<td>' num2str(r.time,'%.4f') '</td>' ...
                        '<td>' r.signal '</td>' ...
                        '<td>' num2str(r.expected) '</td>' ...
                        '<td>' num2str(r.obtained) '</td>' ...
                        '</tr>'];
                end
            end

            block = ['<div class="card">' ...
                     '<div class="module-title">Test Case: ' ts '</div>'];

            if ~isempty(rowsExp)
                block = [block ...
                    '<h3>MIL vs Expected</h3>' ...
                    '<table>' ...
                    '<tr><th>S.No</th><th>Time</th><th>Signal</th><th>Expected</th><th>Actual</th></tr>' ...
                    rowsExp '</table>'];
            end

            if ~isempty(rowsSil)
                block = [block ...
                    '<h3>MIL vs SIL</h3>' ...
                    '<table>' ...
                    '<tr><th>S.No</th><th>Time</th><th>Signal</th><th>MIL</th><th>SIL</th></tr>' ...
                    rowsSil '</table>'];
            end

            block = [block '</div>'];

            html = strrep(template,'{{ test_case }}',ts);
            html = regexprep(html,'\{% for module in modules %\}[\s\S]*?\{% endfor %\}',block,'once');

            fid=fopen(fullfile(reportsDir,[moduleName, '_', ts '_failed.html']),'w');
            fwrite(fid,html);
            fclose(fid);
        end
    end
end

function failedData = extract_failed_mil_vs_sil(milFile, silFile, expFile)

    milData = load(milFile);
    silData = load(silFile);
    expData = load(expFile);

    failedData = struct([]);
    idx = 1;

    t = [];
    if isfield(expData,'t')
        t = expData.t(:);
        t = t(2:end);
    end

    vars = fieldnames(expData);
    vars(strcmp(vars,'t')) = [];

    for i=1:numel(vars)

        if ~istable(expData.(vars{i})), continue; end

        base=vars{i};
        milVar=[base '_mil'];
        silVar=[base '_sil'];

        if ~isfield(milData,milVar)||~isfield(silData,silVar), continue; end

        tbl=expData.(base);

        tolVals=table_col_to_double(tbl,'tolerance');
        enVals=table_col_to_double(tbl,'is_enable');

        if isempty(enVals), enVals=true(size(tolVals)); end
        enVals=logical(enVals);

        tolVals=tolVals(2:end);
        enVals=enVals(2:end);

        milVals=to_vector(milData.(milVar)); milVals=milVals(2:end);
        silVals=to_vector(silData.(silVar)); silVals=silVals(2:end);

        n=min(numel(milVals),numel(silVals));

        milVals=milVals(1:n);
        silVals=silVals(1:n);
        tolVals=tolVals(1:n);
        enVals=enVals(1:n);

        if isempty(t)
            tVals = (1:n)';
        else
            tVals = t(1:n);
        end

        idxCheck=find(enVals);
        diff=abs(milVals(idxCheck)-silVals(idxCheck));
        failIdx=idxCheck(diff>tolVals(idxCheck));

        for j=1:numel(failIdx)

            k=failIdx(j);

            failedData(idx).time = tVals(k);
            failedData(idx).signal = base;
            failedData(idx).expected = milVals(k);
            failedData(idx).obtained = silVals(k);

            idx=idx+1;
        end
    end
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

function v = to_vector(x)
    if isnumeric(x) || islogical(x)
        v = double(x(:));
    elseif istable(x)
        v = table_col_to_double(x,'value');
    elseif iscell(x)
        v = nan(numel(x),1);
        for i = 1:numel(x)
            if isnumeric(x{i})
                v(i) = double(x{i});
            end
        end
    else
        v = [];
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

function out = tern(cond,a,b)
    if cond, out = a; else, out = b; end
end

function failedData = extract_failed_mil_vs_expected(milFile, expFile)

    milData = load(milFile);
    expData = load(expFile);

    failedData = struct([]);
    idx = 1;

    t = [];
    if isfield(expData,'t')
        t = expData.t(:);
        t = t(2:end);
    end

    vars = fieldnames(expData);
    vars(strcmp(vars,'t')) = [];

    for i = 1:numel(vars)

        if ~istable(expData.(vars{i})), continue; end

        base = vars{i};
        milVar = [base '_mil'];

        if ~isfield(milData,milVar), continue; end

        tbl = expData.(base);

        expVals = table_col_to_double(tbl,'value');
        tolVals = table_col_to_double(tbl,'tolerance');
        enVals  = table_col_to_double(tbl,'is_enable');

        if isempty(enVals), enVals=true(size(expVals)); end
        enVals=logical(enVals);

        expVals=expVals(2:end);
        tolVals=tolVals(2:end);
        enVals=enVals(2:end);

        milVals=to_vector(milData.(milVar)); milVals=milVals(2:end);

        n=min(numel(milVals),numel(expVals));

        milVals=milVals(1:n);
        expVals=expVals(1:n);
        tolVals=tolVals(1:n);
        enVals=enVals(1:n);

        if isempty(t)
            tVals = (1:n)';
        else
            tVals = t(1:min(n, numel(t)));
        end

        idxCheck=find(enVals);
        diff=abs(milVals(idxCheck)-expVals(idxCheck));
        failIdx=idxCheck(diff>tolVals(idxCheck));

        for j=1:numel(failIdx)

            k=failIdx(j);

            failedData(idx).time = tVals(k);
            failedData(idx).signal = base;
            failedData(idx).expected = expVals(k);
            failedData(idx).actual = milVals(k);

            idx=idx+1;
        end
    end
end