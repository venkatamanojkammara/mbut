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
%  File         :  batch_run.m
%
%  Description  :  Performs Batch Run for the Selected Test Cases Files.
%
% *************************************************************************
function batch_run(excel_paths)

    fig = resolveGuiFig();
    
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    batch_start_time = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
    
    for k = 1:length(excel_paths)
        excel_path = excel_paths{k};
        excel_dir = fileparts(excel_path);
        cd(excel_dir);
        setappdata(fig,'mtcdXlsPath', excel_path);
        try
            doc = xmlread(excel_path);
            modelInfoList = doc.getElementsByTagName('model-info');
            if modelInfoList.getLength == 0
                error('No <model-info> tag found in XML.');
            end
            modelInfo = modelInfoList.item(0);

            mainModelNode = modelInfo.getElementsByTagName('main-model');
            if mainModelNode.getLength > 0
                mainModel = char(mainModelNode.item(0).getAttribute('info'));
            else
                mainModel = '';
            end

            submoduleNode = modelInfo.getElementsByTagName('submodule');
            if submoduleNode.getLength > 0
                submodule = char(submoduleNode.item(0).getAttribute('info'));
            else
                submodule = '';
            end

            savePathNode = modelInfo.getElementsByTagName('save-path');
            if savePathNode.getLength > 0
                frame_path = char(savePathNode.item(0).getAttribute('info'));
            else
                frame_path = '';
            end
            if isempty(mainModel) || isempty(submodule) || isempty(frame_path)
                error('Invalid model info format in J2.');
            end
        catch ME
            msgbox('batch_run:InvalidModelInfo', ...
                  'Failed to read model info from J2:\n%s', ME.message);
              continue;
        end

        [test_folder_path,~,~] = fileparts(excel_path);
        [~,submodule_name,~]  = fileparts(submodule);

        slx_name = ['Test_Frame_', submodule_name, '_tl.slx'];
        slx_path = fullfile(test_folder_path, slx_name);

        if exist(slx_path,'file') ~= 4
            error('batch_run:SLXNotFound', ...
                  'SLX file not found:\n%s', slx_path);
        end
        open_system(slx_path);        
        xmlDoc = xmlread(excel_path);
        testCaseNodes = xmlDoc.getElementsByTagName('test-case');
        total_nodes = testCaseNodes.getLength;

        test_case_names = {};
        for i = 0:total_nodes-1
            node = testCaseNodes.item(i);
            tc_id = char(node.getAttribute('test-case-id'));
            if startsWith(tc_id, 'TS_')
                test_case_names{end+1,1} = tc_id;
            end
        end

        total_test_cases = numel(test_case_names);
        if total_test_cases == 0
            error('batch_run:NoTestCases', 'No TS_ test cases found in XML.');
        end

        exists_flag = false(total_test_cases,1);
        for i = 1:total_test_cases
            folder_to_check = fullfile(test_folder_path, test_case_names{i});
            exists_flag(i) = exist(folder_to_check, 'dir') == 7;
        end

        existing_folders = test_case_names(exists_flag);
        missing_folders  = test_case_names(~exists_flag);
        if ~isempty(missing_folders)
            error('batch_run:TestCasesNotLoaded','The following test case folders are missing:\n%s', strjoin(missing_folders, ', '));
        end

        milChk = 1;
        silChk = 0;
        [~, frame_name, ~] = fileparts(slx_name);
        try
            % Run MIL
            commandLog(logFile, 'Executing Batch Run for %s', excel_path);
            commandLog(logFile, 'Batch Run -> MIL for %s', excel_path);
            fcn_Simulate_frame(excel_path, test_case_names, milChk, silChk, frame_name);
            
            % Code generation
            commandLog(logFile, 'Batch Run -> Code Generation for %s', excel_path);
            ok = generate_code(frame_name);

            if ~ok
                error('Code generation failed.');
            end

            % Run SIL
            milChk = 0;
            silChk = 1;
             commandLog(logFile, 'Batch Run -> SIL for %s', excel_path);
            fcn_Simulate_frame(excel_path, test_case_names, milChk, silChk, frame_name);
            commandLog(logFile, 'Batch Run completed for %s', excel_path);
        catch
            continue;
        end
    end
    
    batch_end_time = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
    batch_total_execution_time = batch_end_time - batch_start_time;
    total_execution_time = batch_total_execution_time;
    setappdata(fig,'total_execution_time', total_execution_time);
    pushWS(fig,'total_execution_time',total_execution_time);
    
    generateHTMLReport(excel_paths)
  
end

function result = generate_code(frame_name)
    fig = resolveGuiFig();
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    commandLog(logFile, 'Code Generation Started.');
    
    baseDir = fileparts(excelFile);
    cd(baseDir);
    
    hSubsystem = dsdd('Find', '/Subsystems', 'ObjectKind', 'Subsystem');
    for i = 1:length(hSubsystem)
        dsdd('Delete', hSubsystem(i));
    end
    hMainTLDialog = find_system(frame_name,'MaskType', 'TL_MainDialog');
    tl_set(hMainTLDialog, 'codecoveragelevel', 2,'codeopt.cleancode',0,'logopt.globalloggingmode',1);
        
    cmd = sprintf('tl_build_host(''Model'', ''%s'', ''IncludeSubItems'', ''on'')', frame_name);
    text = evalc(cmd);
    result = contains(text, 'GENERATING SYMBOL TABLE SUCCEEDED') && contains(text, 'GENERATING SYMBOL TABLE');
    if result==1
        commandLog(logFile, 'Code Generation Succesfully completed.');
    else
        commandLog(logFile, 'Issue in Generating Code');
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