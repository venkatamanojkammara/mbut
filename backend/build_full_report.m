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
%  File         :  build_full_report.m
%
%  Description  :  Consolidating all the report generating functions.
%
% *************************************************************************
function indexHtmlPath = build_full_report(excelPaths, templatesDir)
    if nargin < 2
        error('Usage: build_full_report(excelPaths, templatesDir)');
    end

    if ischar(excelPaths)
        excelPaths = {excelPaths};
    end

    numExcels = numel(excelPaths);

    if numExcels == 1
        % EXISTING BEHAVIOR (UNCHANGED)
        baseDir = fileparts(excelPaths{1});
        reportsDir = fullfile(baseDir, 'Reports');
    else
        % BATCH MODE
        firstExcel = excelPaths{1};
        reportsDir = fullfile( ...
            fileparts(fileparts(firstExcel)),'BatchRunReports');
    end

    if ~exist(reportsDir, 'dir')
        mkdir(reportsDir);
    end

    fprintf('\nReports directory:\n%s\n\n', reportsDir);

    fprintf('Generating requirements report...\n');
    generate_requirements_report(excelPaths, templatesDir, reportsDir);

    fprintf('Generating overview report...\n');
    generate_overview_html(excelPaths, templatesDir, reportsDir);

    fprintf('Generating variables report...\n');
    generate_variables_report(excelPaths, templatesDir, reportsDir);

    fprintf('Generating coverage report...\n');
    generate_coverage_report(excelPaths, templatesDir, reportsDir);

    fprintf('Generating index.html...\n');
    indexHtmlPath = generate_index_html(reportsDir, templatesDir);

    fprintf('\nHTML report generation completed successfully.\n');
end