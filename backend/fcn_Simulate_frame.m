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
%  Author       :  Guddeti Jagadeesh Reddy
%  Department   :  IDSIA
%  File         :  fcn_Simulate_frame.m
%
%  Description  :  Simulates the Test Frame on Test Cases.
%
% *************************************************************************
function simulation_flag = fcn_Simulate_frame(excel_path, TestseqID, milChk, silChk, frame_name)

    fig = resolveGuiFig();

    excelFile = getappdata(fig, 'mtcdXlsPath');
    logFile   = fullfile(fileparts(excelFile), 'commandLog.txt');
    simulation_flag = 0;
    Test_folder = fileparts(excel_path);
    
    userdefined_func_json = fullfile(Test_folder, 'userdefined_scripts.json');
    
    if exist(userdefined_func_json, 'file')
        rawText = fileread(userdefined_func_json);
        registry = jsondecode(rawText);
        if isempty(fieldnames(registry))
            disp('No scripts found in JSON');
            return;
        end
        fnames = fieldnames(registry);
   
        for i = 1:numel(fnames)
            funcName = fnames{i};
            filePath = registry.(funcName);
            fprintf('Running: %s\n', funcName);
            addpath(fileparts(filePath));
            try
                feval(funcName);
            catch ME
                warning('Error running %s: %s', funcName, ME.message);
            end
        end
        disp('User Defined scripts executed');
    end
    
    global temp_param;
    temp_param = {};
    
    cd(Test_folder);
    exec_time = getappdata(fig, 'exec_time');
    dataPath = dir(fullfile(fileparts(excel_path), '*_data'));
    txtFilePath = fullfile([dataPath.folder, '\', dataPath.name], 'outports.json');
    
    if isempty(exec_time)
        exec_time.mil   = duration(0,0,0);
        exec_time.sil   = duration(0,0,0);
        exec_time.total = duration(0,0,0);
    end
    
    if milChk && ~silChk
        exec_time.sil = duration(0,0,0);
        exec_time.mil   = duration(0,0,0);
    elseif silChk && ~milChk
        exec_time.sil = duration(0,0,0);
    elseif milChk && silChk
        exec_time.mil = duration(0,0,0);
        exec_time.sil = duration(0,0,0);
    end
    
    coverage_type = getappdata(fig, 'code_coverage_type');
    coverage_type_value = coverage_type.Value;
    
    
    
    
    try
        % -------- MIL ONLY --------
        if milChk && ~silChk
            setStatus(fig,'Running MIL Test Case(s)...');
            commandLog(logFile,'Running MIL Test Case(s)...');
            mil_start = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
            convert_to_mil(frame_name);
            execution(TestseqID, Test_folder, 1, 0, excel_path);
            auto_plot_signals_from_mat(Test_folder, TestseqID, txtFilePath, 1, 0);
            mil_elapsed = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss') - mil_start;
            exec_time.mil = mil_elapsed;
            commandLog(logFile,'MIL Simulation Completed.');
            commandLog(logFile,'Generated plots for Output Signals - MIL vs Expected');
            msgbox('Simulation completed successfully using Test Frame', 'Success');
            setStatus(fig,'Ready');
            
        % -------- SIL ONLY --------
        elseif silChk && ~milChk
            setStatus(fig,'Running SIL Test Case(s)...');
            commandLog(logFile,'Running SIL Test Case(s)...');
            sil_start = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
            convert_to_sil(frame_name);
            if coverage_type_value == 1
                msgbox('Select any Coverage Type', 'Warning');
                return;
            elseif coverage_type_value == 2
                coverage_type_value = 1;
            else 
                coverage_type_value = 2;
            end
            try
                hMainTLDialog = find_system(frame_name,'MaskType', 'TL_MainDialog');
                tl_set(hMainTLDialog, 'codecoveragelevel', coverage_type_value,'codeopt.cleancode',0,'logopt.globalloggingmode',1);
            catch ME
                msgbox(ME.message, 'Warning');
            end
            execution(TestseqID, Test_folder, 0, 1, excel_path);
            auto_plot_signals_from_mat(Test_folder, TestseqID, txtFilePath, 1, 1);
            sil_elapsed = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss') - sil_start;
            exec_time.sil = sil_elapsed;
            commandLog(logFile,'SIL Simulation Completed.');
            commandLog(logFile,'Generated plots for Output Signals - MIL vs SIL');
            msgbox('Simulation completed successfully using Test Frame', 'Success');
            setStatus(fig,'Ready');
            
        % -------- BACK-TO-BACK --------
        elseif silChk && milChk
            setStatus(fig,'Running Back to Back Test Case(s)...');
            commandLog(logFile,'Running Back to Back Test Case(s)...');
            % ---- MIL ----
            mil_start = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
            convert_to_mil(frame_name);
            execution(TestseqID, Test_folder, 1, 0, excel_path);
            mil_elapsed = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss') - mil_start;
            exec_time.mil =  mil_elapsed;
            % ---- CODE GENERATION ----
            setStatus(fig,'Generating Code...');
            result = generate_code(frame_name);
            % ---- SIL ----
            if result == 1
                sil_start = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
                convert_to_sil(frame_name);
                execution(TestseqID, Test_folder, 0, 1, excel_path);
                sil_elapsed = datetime(datestr(now,'dd-mm-yyyy HH:MM:SS'), 'InputFormat', 'dd-MM-yyyy HH:mm:ss') - sil_start;
                exec_time.sil = sil_elapsed;
                commandLog(logFile,'Back to Back Simulation Completed.');
            else
                commandLog(logFile,'Code generation failed. SIL skipped.');
            end
            msgbox('Simulation completed successfully using Test Frame', 'Success');
            setStatus(fig,'Ready');
            
        % -------- INVALID CASE --------
        else
            error('Select MIL or/and SIL');
        end
        
        

    catch ME
        try
            err = ME.cause{2,1}.message;
            msgbox(err,'Error');
            commandLog(logFile, 'ERROR: %s' ,err);
        catch ME
            msgbox(ME.message,'Error');
        end

        setStatus(fig,'Ready');
    end

    exec_time.total = exec_time.mil + exec_time.sil;
    setappdata(fig,'exec_time', exec_time);
    total_execution_time = exec_time.total;
    
    % commandLog(logFile, 'Execution Time: %s', char(total_execution_time));
    commandLog(logFile, ['MIL Time   : ' char(exec_time.mil)]);
    commandLog(logFile, ['SIL Time   : ' char(exec_time.sil)]);
    commandLog(logFile, ['Total Time : ' char(total_execution_time)]);
    setappdata(fig,'total_execution_time', total_execution_time);
    pushWS(fig,'total_execution_time', total_execution_time);

    disp(['MIL Time   : ' char(exec_time.mil)]);
    disp(['SIL Time   : ' char(exec_time.sil)]);
    disp(['Total Time : ' char(total_execution_time)]);
end

function execution(TestseqID, Test_folder, milChk, silChk, excel_path)

    fig = resolveGuiFig();
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');

    for i = 1:numel(TestseqID)
        currentID = TestseqID{i};
        Test_case_path = fullfile(Test_folder, currentID); 
        test_data_path = fullfile(Test_case_path, [currentID, '_test_data.mat']);
 
        Mi_test_data_path = fullfile(Test_case_path, [currentID, '_test_data_temp.mat']);
        mat_file_name=[currentID,'_output_data.mat'];
        test_data_mat = load(test_data_path);
        time = test_data_mat.t;
        sim_time = time(end);

        flg_mdl_present = 0;
        files = dir(fullfile(Test_folder, '**', '*.slx'));
        frame_name_slx= files.name;
        slxPaths = fullfile({files.folder}, {files.name})';

        if isempty(slxPaths)
            fprintf('No .slx files found under: %s\n', rootFolder);
        else
           flg_mdl_present = 1;
        end

        empty_parameter_file = 0;
        
        if flg_mdl_present
            test_dir = fileparts(excel_path);
            parameter_dir = fullfile(test_dir, TestseqID{i});
            changing_parameter_file = [char(TestseqID{i}), '_changing_parameters.json'];
            changing_parameters_path = char(fullfile(parameter_dir, changing_parameter_file));

            fid = fopen(changing_parameters_path, 'r');

            if fid == -1
                error('Cannot open file: %s', changing_parameters_path);
            end

            rawText = fread(fid, '*char')';
            fclose(fid);

            rawText = strtrim(rawText);

            % Check empty JSON
            if isempty(rawText) || strcmp(rawText, '{}')
                empty_parameter_file = 1;
            else
                empty_parameter_file = 0;
            end

            if empty_parameter_file == 0

                % --- Decode JSON
                try
                    data = jsondecode(rawText);
                catch
                    error('Invalid JSON format in: %s', changing_parameters_path);
                end

                temp_param = {};

                for l = 1:length(data)

                    parameter_name = strtrim(data(l).name);
                    parameter_value = data(l).value;

                    % Convert string numbers ? numeric if needed
                    if ischar(parameter_value) || isstring(parameter_value)
                        numVal = str2double(parameter_value);
                        if ~isnan(numVal)
                            parameter_value = numVal;
                        end
                    end

                    temp_param{l} = parameter_name;

                    % Assign to base workspace
                    assignin('base', parameter_name, parameter_value);

                end
            end

            fprintf('Parameters updated and *_actual created.\n');

            wrk_spc_path = sprintf('load(''%s'')', Mi_test_data_path);
            evalin('base', wrk_spc_path);

            % test_dir = fileparts(excel_path);
            % d = dir(test_dir);
            % d = d([d.isdir] & ~ismember({d.name},{'.','..'}));
            % matches = d(endsWith({d.name}, '_data', 'IgnoreCase', true));
            % matchPaths = fullfile(test_dir, {matches.name});
            % data_dir = matchPaths{1};
            % inports_file = fullfile(data_dir, 'inports.txt');
        
            sim_mdl_str = sprintf('sim(''%s'', %d)', slxPaths{1}, sim_time);
            ut_folder = fileparts(slxPaths{1});
            cd(ut_folder);
            evalin('base', sim_mdl_str);
            
        else
            msgbox(['Model Not present for ', currentID]);
            continue;
        end
    
                % Get data folder
        [~, data_folder, ~] = fileparts(fileparts(Test_case_path));

        data_folder_temp = strrep(data_folder, 'Test_', '');

        data_folde_path = fullfile(Test_case_path, [currentID, '_changing_parameters.json']);
        % Open file
        fid = fopen(data_folde_path, 'r');

        if fid == -1
            error('Cannot open file: %s', data_folde_path);
        end

        rawText = fread(fid, '*char')';
        fclose(fid);

        rawText = strtrim(rawText);

        % Check empty JSON
        if isempty(rawText) || strcmp(rawText, '{}')
            empty_parameter_file = 1;
        else
            empty_parameter_file = 0;
        end

        % Load JSON into workspace
        if empty_parameter_file == 0
            try
                data = jsondecode(rawText);
            catch
                error('Invalid JSON format in: %s', data_folde_path);
            end

            for l = 1:length(data)

                parameter_name  = strtrim(data(l).name);
                parameter_value = data(l).value;

                % Convert string numeric ? double
                if ischar(parameter_value) || isstring(parameter_value)
                    val_num = str2double(parameter_value);
                    if ~isnan(val_num)
                        parameter_value = val_num;
                    end
                end

                % Assign into base workspace
                assignin('base', parameter_name, parameter_value);
            end
        end    
        
        simulation_datetime_path = fullfile(Test_folder, 'simulation_datetime_data.mat');
        if exist(simulation_datetime_path, 'file')
            loaded_data = load(simulation_datetime_path);
            if isfield(loaded_data, 'simulation_datetime_data')
                data_struct = loaded_data.simulation_datetime_data;
            else
                data_struct = struct([]);
            end
        else
            data_struct = struct([]);
        end
 
        new_entry = struct('testId', currentID, 'datetime', datestr(datetime('now')));
        if isempty(data_struct)
            data_struct = new_entry;
        else
            data_struct(end+1) = new_entry;
        end
 
        simulation_datetime_data = struct('simulation_datetime_data', data_struct);
        save(simulation_datetime_path, '-struct', 'simulation_datetime_data');
    
        try
            movefile(simulation_datetime_path, Test_case_path, 'f');
        catch
              movefile(simulation_datetime_path, Test_case_path);
        end

        if milChk
            setStatus(fig, ['Running MIL Test Case...' TestseqID{i} '']);
            commandLog(logFile, ['Running MIL Test Case...' TestseqID{i} '']);
            get_outp_sigs(frame_name_slx, Test_case_path, mat_file_name, '_mil');
        elseif silChk
            setStatus(fig, ['Running SIL Test Case...' TestseqID{i} '']);
            commandLog(logFile, ['Running SIL Test Case...' TestseqID{i} '']);
            get_outp_sigs(frame_name_slx, Test_case_path, mat_file_name, '_sil');
        elseif milChk && silChk
            get_outp_sigs(frame_name_slx, Test_case_path, mat_file_name, '_mil');
            get_outp_sigs(frame_name_slx, Test_case_path, mat_file_name, '_sil');
        else
            disp('Select MIL and/or SIL');
        end
        simulation_flag = 1;
    end 
end


function convert_to_mil(frame_name)
    set_param(frame_name,'PostSaveFcn','');
    tl_set_sim_mode('model', frame_name, 'SimMode', 'TL_BLOCKS_HOST');
end

function convert_to_sil(frame_name)
    set_param(frame_name,'PostSaveFcn','');
    tl_set_sim_mode('Model',frame_name,'simmode','TL_CODE_HOST');
end

function result = generate_code(frame_name)
    cmd = sprintf('tl_build_host(''Model'', ''%s'', ''IncludeSubItems'', ''on'')', frame_name);
    text = evalc(cmd);
    result = contains(text, 'GENERATING TABLE SUCCEEDED') && contains(text, 'GENERATING SYMBOL TABLE');
end

function copy_data_into_base_workspace(parameter_path)

    global temp_param;

    fid = fopen(parameter_path, 'r');
    if fid == -1
        error('Cannot open file: %s', parameter_path);
    end

    rawText = fread(fid, '*char')';
    fclose(fid);

    rawText = strtrim(rawText);

    % Check empty JSON
    if isempty(rawText) || strcmp(rawText, '{}')
        return;
    end

    % Decode JSON
    try
        data = jsondecode(rawText);
    catch
        error('Invalid JSON format in: %s', parameter_path);
    end

    % Loop through parameters
    for l = 1:length(data)

        parameter_name  = strtrim(data(l).name);
        parameter_value = data(l).value;

        % ? Only assign if in temp_param (your original logic)
        if ismember(parameter_name, temp_param)

            % Convert string numeric ? double
            if ischar(parameter_value) || isstring(parameter_value)
                val_num = str2double(parameter_value);
                if ~isnan(val_num)
                    parameter_value = val_num;
                end
            end

            % Assign to base workspace
            assignin('base', parameter_name, parameter_value);
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

function setStatus(fig, msg)
    h = getappdata(fig,'statusText');
    if ~isempty(h) && ishandle(h)
        set(h,'String',msg);
        drawnow;
    end
    pushWS(fig,'STATUS',msg);
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