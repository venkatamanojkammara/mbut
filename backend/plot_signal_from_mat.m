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
%  Author       :  Shaik Sameer
%  Department   :  IDSIA
%  File         :  plot_signal_from_mat.m
%
%  Description  :  Plot the Desired Output Signal.
%
% *************************************************************************
function plot_signal_from_mat(folderName, testCaseName, signalName, mil, sil)
 
    fig = resolveGuiFig();
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    % Build paths
    expectedFile = fullfile(folderName, testCaseName, [testCaseName '_expected_output.mat']);
    milFile      = fullfile(folderName, testCaseName, [testCaseName '_output_data_mil.mat']);
    silFile      = fullfile(folderName, testCaseName, [testCaseName '_output_data_sil.mat']);
 
    if ~exist(expectedFile,'file'), error('Expected file missing'); end
    if ~exist(milFile,'file'), error('MIL file missing'); end
   
    % Load MAT files
    expData = load(expectedFile);
    milData = load(milFile);
    
 
    %% Expected signal
    if ~isfield(expData, signalName)
        error('Expected signal "%s" not found', signalName);
    end
 
    expSignal = expData.(signalName);
    expValues = expSignal.value(:,1);
 
    if iscell(expValues)
        expValues = cell2mat(expValues);
    end
 
    expTime = expData.t;
 
    %% MIL signal
    milSignalName = [signalName '_mil'];
 
    if ~isfield(milData, milSignalName)
        error('MIL signal "%s" not found', milSignalName);
    end
 
    milValues = milData.(milSignalName);
 
    if iscell(milValues)
        milValues = cell2mat(milValues);
    end
 
    if ~isfield(milData,'t')
        error('MIL time vector "t" missing');
    end
 
    milTime = milData.t;
    
    %% SIL signal
    
    %% Compute mil vs expected deviation
    minLen = min(length(expValues), length(milValues));
    deviation = milValues(1:minLen) - expValues(1:minLen);
    
   
    %% Underscore-safe name
    signalNameSafe = strrep(signalName,'_','\_');
 
    %% ============================
    %  SINGLE PLOT VERSION
    %% ============================
 
    figure('Name',['Signal: ' signalName], 'NumberTitle','off');
    hold on; grid on;
    
    if mil && ~sil
        commandLog(logFile, 'Plotting signal on MIL vs Expected vs Deviation for %s', signalName);
        plot(milTime, milValues, 'b', 'LineWidth', 1.5);
        plot(expTime, expValues, 'g', 'LineWidth', 1.5);
        plot(expTime(1:minLen), deviation, 'r', 'LineWidth', 1.5);

        title(['MIL vs Expected vs Deviation - ' signalNameSafe]);
        xlabel('Time');
        ylabel('Value');

        legend('MIL', 'Expected', 'Deviation (MIL - Expected)', 'Location', 'best');

        hold off;
    elseif sil && mil
        
        if ~exist(silFile,'file'), error('SIL file missing'); end
        silData = load(silFile);
        %if ~exist(silFile,'file'), error('SIL file missing'); end
        silSignalName = [signalName '_sil'];

        if ~isfield(silData, silSignalName)
            error('SIL signal "%s" not found', silSignalName);
        end

        silValues = silData.(silSignalName);

        if iscell(silValues)
            silValues = cell2mat(silValues);
        end

        if ~isfield(silData,'t')
            error('SIL time vector "t" missing');
        end

        silTime = silData.t;
        
         %% mil vs sil deviation
        sil_minLen = min(length(milValues), length(silValues));
        sil_deviation = silValues(1:sil_minLen) - milValues(1:sil_minLen);

        signalNameSafe = strrep(signalName,'_','\_');
        commandLog(logFile, 'Plotting signal on MIL vs SIL vs Deviation for %s', signalName);
        plot(milTime, milValues, 'b', 'LineWidth', 1.5);
        plot(silTime, silValues, 'g', 'LineWidth', 1.5);
        plot(silTime(1:sil_minLen), sil_deviation, 'r', 'LineWidth', 1.5);

        title(['MIL vs SIL vs Deviation - ' signalNameSafe]);
        xlabel('Time');
        ylabel('Value');

        legend('SIL', 'MIL', 'Deviation (SIL - MIL)', 'Location', 'best');

        hold off;
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