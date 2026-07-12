function indexHtmlPath = generateHTMLReport(path)
fig = resolveGuiFig();
if ischar(path), excelPaths={path}; elseif iscell(path), excelPaths=path; else, error('path must be a string or cell array of strings.'); end
templatesDir=getappdata(fig,'templatesDir');
if isempty(templatesDir), templatesDir=fullfile(fileparts(fileparts(mfilename('fullpath'))),'report_templates'); end
if exist(templatesDir,'dir')~=7, error('Report templates directory not found: %s',templatesDir); end
setStatus(fig,'Generating HTML Report...');
indexHtmlPath=build_full_report(excelPaths,templatesDir);
try, web(indexHtmlPath,'-browser'); catch, warning('Could not open HTML report automatically.'); end
setStatus(fig,'Ready');
end
