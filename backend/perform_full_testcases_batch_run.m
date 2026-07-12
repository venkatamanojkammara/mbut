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
%  File         :  perform_full_testcases_batch_run.m
%
%  Description  :  Perform Full run for test cases, form Frame Creation to Comnolidated Report Generation.
%
% *************************************************************************
function perform_full_testcases_batch_run(xmlFiles, fig)

    
    batch_start_time = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');

    for i = 1:length(xmlFiles)

        Paths = xmlFiles(i);
        fullPath = [Paths.folder, '\', Paths.name];
        fileName = Paths.name;
        setappdata(fig,'mtcdXlsPath', fullPath);
        pushWS(fig,'mtcdXlsPath', fullPath);
        
        try
            doc = xmlread(char(fullPath));
            modelInfoList = doc.getElementsByTagName('model-info');
            if modelInfoList.getLength == 0
                error('No <model-info> tag found in XML.');
            end
            modelInfo = modelInfoList.item(0);

            % ---- MAIN MODEL ----
            mainModelNode = modelInfo.getElementsByTagName('main-model');
            if mainModelNode.getLength > 0
                mainModel = char(mainModelNode.item(0).getAttribute('info'));
            else
                mainModel = '';
            end

            % ---- SUBMODULE ----
            submoduleNode = modelInfo.getElementsByTagName('submodule');
            if submoduleNode.getLength > 0
                submodule = char(submoduleNode.item(0).getAttribute('info'));
            else
                submodule = '';
            end

            % ---- SAVE PATH ----
            savePathNode = modelInfo.getElementsByTagName('save-path');
            if savePathNode.getLength > 0
                savePath = char(savePathNode.item(0).getAttribute('info'));
            else
                savePath = '';
            end
            
            xmlDir = string(fileparts(char(fullPath)));
            xmlDirNorm   = string(xmlDir);
            savePathNorm = string(fullfile(char(savePath)));

            if savePathNorm ~= '' && ~strcmpi(savePathNorm, xmlDirNorm)
                savePath = char(xmlDir);
            end
            
            setappdata(fig,'mainModelPath', mainModel);
            setappdata(fig,'submodulePath', submodule);
            setappdata(fig,'savePath', savePath);
            
            try 
                [~, final_slx_path] = Frame_Creation1(mainModel, submodule, savePath);
                % copyfile(fullPath, fileparts(final_slx_path));
                movefile(fullPath, fileparts(final_slx_path));
                fullPath = [fileparts(final_slx_path), '\', fileName];
                
            catch ME
                msgbox(['Frame Creation:' ME.message], 'Warning');
                continue;
            end
            
            dataPath = dir(fullfile(fileparts(fullPath), '*_data'));
            dataFolderPath = [dataPath.folder, '\', dataPath.name];
            
            try 
                timestep = 0.01;
                build_from_xml(fullPath, timestep, dataFolderPath);
                test_folder_path = fileparts(fullPath);
            catch ME
                msgbox(['Test Cases Loading:' ME.message], 'Warning');
                continue;
            end
            
            try
                testCaseNodes = doc.getElementsByTagName('test-case');
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
                    error('batch_run:NoTestCases','No TS_ test cases found in XML.');
                end

                exists_flag = false(total_test_cases,1);
                for i = 1:total_test_cases
                    folder_to_check = fullfile(test_folder_path, test_case_names{i});
                    exists_flag(i) = exist(folder_to_check, 'dir') == 7;
                end

                existing_folders = test_case_names(exists_flag);
                missing_folders  = test_case_names(~exists_flag);

                if ~isempty(missing_folders)
                    error('batch_run:TestCasesNotLoaded', 'The following test case folders are missing:\n%s', strjoin(missing_folders, ', '));
                end

                milChk = 1;
                silChk = 0;
                
                [~, frame_name, ~] = fileparts(final_slx_path);

                try
                    fcn_Simulate_frame(fullPath, test_case_names, milChk, silChk, frame_name);
                    ok = generate_code(frame_name, fullPath);
                    if ~ok
                        error('Code generation failed.');
                    end
                    milChk = 0;
                    silChk = 1;
                    fcn_Simulate_frame(fullPath, test_case_names, milChk, silChk, frame_name);   
                catch
                    
                    continue;
                end
            catch ME
                msgbox(['Simulation:' ME.message], 'Warning');
                continue;
            end
            
        catch ME
            msgbox(ME.message, 'Error');
            continue;
        end

    end
    
    batch_end_time = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
    batch_total_execution_time = batch_end_time - batch_start_time;
    total_execution_time = batch_total_execution_time;
    setappdata(fig,'total_execution_time', total_execution_time);
    pushWS(fig,'total_execution_time',total_execution_time);
    
    generateHTMLReport(xmlFiles)


   

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

function setStatus(fig, msg)
    h = getappdata(fig,'statusText');
    if ~isempty(h) && ishandle(h)
        set(h,'String',msg);
        drawnow;
    end
    pushWS(fig,'STATUS',msg);
end

function val = getUIOrAppdata(fig, h, key)
    val = '';

    if ~isempty(h) 
         if ishandle(h)
            try
                val = get(h,'String');
            catch
                val = '';
            end
         end
    end

    if isempty(val)
        tmp = getappdata(fig,key);
        if ~isempty(tmp)
            val = tmp;
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



function result = generate_code(frame_name, fullPath)
    
    
    baseDir = fileparts(fullPath);
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

end
