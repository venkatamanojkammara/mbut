% ***********************************************************************************************************************
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
% ***********************************************************************************************************************
%
%  Created  on  :  26-03-2020
%  Author       :  Venkata Manoj Kammara
%  Department   :  IDSI
%  File         :  auto_plot_signals_from_mat.m
%
%  Description  :  Automatically Plots the output signals for all Test Cases immediately after the Test Cases Execution. 
%                  [MIL vs Expected] and [MIL vs SIL]
%                  
% ***********************************************************************************************************************
function auto_plot_signals_from_mat(folderName, testCaseNames, txtFilePath, mil, sil)
    fig = resolveGuiFig();
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');

    if ~iscell(testCaseNames)
        error('testCaseNames must be a cell array');
    end
    
    fid = fopen(txtFilePath, 'r');
    if fid == -1
        error('Cannot open file: %s', txtFilePath);
    end

    rawText = fread(fid, '*char')';
    fclose(fid);

    rawText = strtrim(rawText);

    if isempty(rawText) || strcmp(rawText, '{}')
        signalList = {};
    else
        try
            data = jsondecode(rawText);
        catch
            error('Invalid JSON format in: %s', txtFilePath);
        end

        signalList = {};
        for i = 1:length(data)
            if isfield(data(i),'signal')
                signalList{end+1} = strtrim(data(i).signal);
            elseif isfield(data(i),'name')
                signalList{end+1} = strtrim(data(i).name);
            end
        end
    end

    for tc = 1:length(testCaseNames)

        testCaseName = strtrim(testCaseNames{tc});
        expectedFile = fullfile(folderName, testCaseName, [testCaseName '_expected_output.mat']);
        milFile      = fullfile(folderName, testCaseName, [testCaseName '_output_data_mil.mat']);
        silFile      = fullfile(folderName, testCaseName, [testCaseName '_output_data_sil.mat']);

        if ~exist(expectedFile,'file') || ~exist(milFile,'file')
            continue;
        end

        expData = load(expectedFile);
        milData = load(milFile);

        outDir = fullfile(folderName, testCaseName, 'plots');
        if ~exist(outDir, 'dir')
            mkdir(outDir);
        end

        for i = 1:length(signalList)
            signalName = strtrim(signalList{i});
            try
                if ~isfield(expData, signalName)
                    continue;
                end
                
                expSignal = expData.(signalName);
                if isempty(expSignal.value)
                    continue;
                end

                expValues = expSignal.value(:,1);
                if iscell(expValues)
                    expValues = cell2mat(expValues);
                end
                expTime = expData.t;
                milSignalName = [signalName '_mil'];
                if ~isfield(milData, milSignalName)
                    continue;
                end

                milValues = milData.(milSignalName);
                if iscell(milValues)
                    milValues = cell2mat(milValues);
                end
                milTime = milData.t;
                minLen = min(length(expValues), length(milValues));
                deviation = milValues(1:minLen) - expValues(1:minLen);

                %Plot
                figure('Visible','off');
                hold on; grid on;

                if mil && ~sil
                    plot(milTime, milValues, 'b');
                    plot(expTime, expValues, 'g');
                    plot(expTime(1:minLen), deviation, 'r');

                    title(['MIL vs Expected - ' signalName]);
                    legend('MIL','Expected','Deviation');
                    suffix = 'MIL_vs_Expected';
                end

                if mil && sil
                    if ~exist(silFile,'file'), continue; end
                    silData = load(silFile);

                    silSignalName = [signalName '_sil'];
                    if ~isfield(silData, silSignalName)
                        continue;
                    end

                    silValues = silData.(silSignalName);
                    if iscell(silValues)
                        silValues = cell2mat(silValues);
                    end

                    silTime = silData.t;
                    sil_minLen = min(length(milValues), length(silValues));
                    sil_dev = silValues(1:sil_minLen) - milValues(1:sil_minLen);

                    plot(milTime, milValues, 'b');
                    plot(silTime, silValues, 'g');
                    plot(silTime(1:sil_minLen), sil_dev, 'r');

                    title(['MIL vs SIL - ' signalName]);
                    legend('MIL','SIL','Deviation');
                    suffix = 'MIL_vs_SIL';
                end

                xlabel('Time');
                ylabel('Value');
                hold off;

                %% Save
                imgName = fullfile(outDir,[testCaseName '_[' signalName ']_' suffix '.png']);
                saveas(gcf, imgName);
                close(gcf);

            catch
                continue;
            end
        end
        commandLog(logFile, 'Plotted output signals for %s', testCaseName);
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