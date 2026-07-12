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
%  File         :  generate_index_html.m
%
%  Description  :  Generates Index page in the Reports.
%
% *************************************************************************
function indexHtmlPath = generate_index_html(reportsDir, templatesDir)

    if nargin < 2
        error('Usage: generate_index_html(reportsDir, templatesDir)');
    end

    if ~exist(reportsDir, 'dir')
        error('Reports directory does not exist: %s', reportsDir);
    end

    templatePath = fullfile(templatesDir, 'index_template.html');
    if ~exist(templatePath, 'file')
        error('index_template.html not found in %s', templatesDir);
    end

    html = fileread(templatePath);

    indexHtmlPath = fullfile(reportsDir, 'index.html');

    fid = fopen(indexHtmlPath, 'w');
    if fid == -1
        error('Failed to create index.html in %s', reportsDir);
    end

    fwrite(fid, html);
    fclose(fid);

    fprintf('index.html generated successfully: %s\n', indexHtmlPath);

end

function name = getFileName(path)

if isempty(path)
    name = '';
    return;
end

[~, file, ext] = fileparts(path);
name = [file ext];

end