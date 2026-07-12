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
%  File         :  Frame_Creation1.m
%
%  Description  :  Creates Test Frame. Extracts Inputs, Outputs, Parameters.
%
% *************************************************************************
function [frame_gen_flag,final_slx_path] = Frame_Creation1(main_model_name, frame_model_path, frame_path)%frame_path:destination path to svae the or create the fram
    
    fig = resolveGuiFig();
    cd(frame_path);
    [~, submodule_name, ~] =  fileparts(frame_model_path);
    excelFile = getappdata(fig,'mtcdXlsPath');
    test_folder = fullfile(frame_path, ['Test_',submodule_name]);
    data_folder = fullfile(test_folder, [submodule_name, '_data']);
    
    if ~exist(test_folder, 'dir')
        mkdir(test_folder);
    end
    
    if ~exist(data_folder, 'dir')
        mkdir(data_folder);
    end
    
    if ~isempty(excelFile)
        logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    else
        logFile = fullfile(frame_path, ['Test_',submodule_name], 'commandLog.txt');
    end
    
    try
        setStatus(fig, ['Extraction of Inputs from ' submodule_name '...']);
        commandLog(logFile, 'Extraction of Inputs from %s ...', submodule_name);
        [inport_master_list, block_path, NM, inports_file_path] = InPort_Extration(frame_model_path, data_folder);
        commandLog(logFile, 'Inputs Extraction Completed.');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error in Input Extraction : ', ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
    end
    
    try
        setStatus(fig, ['Extraction of Outputs from ' submodule_name '...']);
        commandLog(logFile, 'Extraction of Outputs from %s ...', submodule_name);
        [outport_master_list, outports_file_path] = outputPort_Extration1(frame_model_path, data_folder);
        commandLog(logFile, 'Outputs Extraction Completed.');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error in Output Extraction : ', ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
    end
    
    try
        setStatus(fig, ['Extraction of Parameters from ' submodule_name '...']);
        commandLog(logFile, 'Extraction of Parameters from %s ...', submodule_name);
        parameters_file_path = Parameter_Extraction(frame_model_path, data_folder);
        commandLog(logFile, 'Parameters Extraction Completed.');
        setStatus(fig, 'Ready');
    catch ME
        commandLog(logFile, 'ERROR: %s', ME.message);
        setStatus(fig, ['Error in Parameter Extraction : ', ME.message]);
    end
    
    try
        setStatus(fig, ['Creating Test Frame for ' submodule_name '...']);
        commandLog(logFile, 'Creating Test Frame for the submodule for Testing.');
        [frame_gen_flag, final_slx_path]=create_wrkspc(inport_master_list, block_path, NM,outport_master_list,main_model_name,frame_model_path, inports_file_path, outports_file_path, parameters_file_path);
        commandLog(logFile, 'Test Frame creation completed.');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error in creating Test Frame : ', ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
    end
    
    try
        setStatus(fig, ['Pushing parameters into Base Workspace for ' submodule_name '...']);
        commandLog(logFile, 'Pushing the extracted Parameters from into base workspace...');
        push_paramters_to_workspace(parameters_file_path);
        commandLog(logFile, 'Pushing Parameters from into base workspace completed.');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error in pushing parameters to Base Workspace : ', ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
    end
    

    % filePath = mfilename('fullpath');
    % [filePath,~,~] = fileparts(filePath);
    % inports_file = fullfile(filePath,'inports.txt');
    % outports_file = fullfile(filePath,'outports.txt');
    % parameters_file = fullfile(filePath,'parameter.txt');
    % destination_path = fileparts(final_slx_path);
    % 
    % move_data_files_to_destination(inports_file, destination_path)
    % move_data_files_to_destination(outports_file, destination_path)
    % move_data_files_to_destination(parameters_file, destination_path)
    setStatus(fig, 'Ready');
    
end



function [frame_gen_flag,final_slx_path] = create_wrkspc(masterlist,BP,NM,output_master_list,main_model_name,frame_model_path, inports_file_path, outports_file_path, parameters_file_path)
	
	test_i = 0;
	frame_gen_flag = 0;
	scripts_path = mfilename('fullpath');
	path_idx = strfind(scripts_path,'\');
	script_folder_path = scripts_path(1:path_idx(end));
	sample_frame_script_path = [script_folder_path,'frame_s.slx'];

	if bdIsLoaded('frame_sample')
		frame_sample_path = get_param('frame_sample', 'FileName');
		close_system(frame_sample_path, 0);  % 0 = don't save
	end

% 	try
% 		copyfile(sample_frame_script_path,'frame_sample.slx','f');
% 	catch
% 		copyfile(sample_frame_script_path,'frame_sample.slx');
% 	end
% 	%copyfile(ddpath,fileparts(scripts_path));
% 	open_system('frame_sample.slx');
model = 'frame_sample';
new_system(model);
open_system(model);
TestData_position=[100 100 200 200];
InputBus_position=[250 100 350 200];
Output_Bus_position=[550 100 650 200];
TestOutput_position= [700 100 800 200];
% Add subsystem at a specific location
add_block('simulink/Ports & Subsystems/Subsystem', ...
          [model '/Subsystem1'], ...
          'Position', [100 100 200 200]);
add_block('simulink/Ports & Subsystems/Subsystem',[model '/Subsystem2'],'Position', [250 100 350 200]);
add_block('simulink/Ports & Subsystems/Subsystem',[model '/Subsystem3'], ...
          'Position', [550 100 650 200])
 add_block('simulink/Ports & Subsystems/Subsystem',[model '/Subsystem4'], ...
          'Position', [700 100 800 200])


set_param([model '/Subsystem1'], 'Name', 'TestData');

set_param([model '/Subsystem2'], 'Name', 'Input Bus');

set_param([model '/Subsystem3'], 'Name', 'Output Bus');

set_param([model '/Subsystem4'], 'Name', 'TestOutput');
% Delete Inport and Outport inside subsystem
default_blocks={'Input Bus','TestData','Output Bus','TestOutput'};



for loop_for_blocks = 1:length(default_blocks)
   
    subsys = [model, '/', default_blocks{loop_for_blocks}];

    % -------- Delete all lines --------
    lines = find_system(subsys, 'FindAll', 'on', 'Type', 'line');

    for i = 1:length(lines)
        delete_line(lines(i));
    end

    % -------- Delete all blocks --------
    blocks = find_system(subsys, 'SearchDepth', 1, 'Type', 'Block');

    for i = 1:length(blocks)
        if ~strcmp(blocks{i}, subsys)  % avoid deleting subsystem itself
            delete_block(blocks{i});
        end
    end

end

InputBus_position=[InputBus_position(1), InputBus_position(2), InputBus_position(3), InputBus_position(4) + 0];
Output_Bus_position=[Output_Bus_position(1), Output_Bus_position(2), Output_Bus_position(3), Output_Bus_position(4) + 0];
TestData_position=[TestData_position(1), TestData_position(2), TestData_position(3), TestData_position(4) + 0];
TestOutput_position_height=[TestOutput_position(1), TestOutput_position(2), TestOutput_position(3), TestOutput_position(4) + 0];

flag_df=1;
	flag_TL=1;
	temp=  frame_model_path;
	
	while (flag_df==1)
		df = find_system(temp, 'Name', 'DFF Params Dialog');
		if isempty(df)
			[temp, ~, ~] = fileparts(temp);
	    else
		   flag_df=0;
		   class(df);
	    end
	end
	
	while (flag_TL==1)
		TL = find_system(temp,'MaskType','TL_MainDialog');
		TL_name= get_param(TL,'Name');  
		if isempty(df)
			[temp, ~, ~] = fileparts(temp);
		else
			flag_TL=0;
			class(TL);
		end
	end
	
%df='CP_Master_Work/ErgoControl II/ECIIBau'; 
[df, ~, ~] = fileparts(df{1,1});
DFF_Block = [df,'/','DFF Params Dialog'];
add_block(DFF_Block,'frame_sample/DFF Params Dialog','position',[20 50 110 80]);%copying datafield block to testframe from mainmodel
[TL, ~, ~] = fileparts(TL{1,1});
Targetlink_Block = [TL,'/',char(TL_name)];
add_block(Targetlink_Block,['frame_sample','/',char(TL_name)],'position',[150 50 240 80]);
add_block('tllib/MIL Handler', 'frame_sample/MIL Handler','MakeNameUnique', 'on','Position', [305 50 390 80]);

size_inp_data = size(masterlist,1);
size_outport_data = size(output_master_list,1);
temp_cnt = 1;
SZ_mux = 0;
temp_bus_data = '';
[x,y,z,c,d,I] = feval(@(L) L{:},num2cell([0,58,72,273,283,0]));
new_master_list = unique(masterlist(:,2));
new_master_list = new_master_list(~cellfun(@isempty, new_master_list));
size_bus_data = size(new_master_list,1);
[E,F,G,H,i,a] = deal(3000,3700,1,58,72,1);
for loc_for_13 = 1:size_inp_data
    Inpdata = char(masterlist{a,1});
    in_bus_data = char(masterlist{a,2});
    unique_list = regexprep(Inpdata,'\_+\d*$','');
    list(a,1) = mat2cell(unique_list,1);
    a = a+1;
end
unique_master_list = unique(list(:,1));%identifing the input signals inside bus 
size_uniquelist = size(unique_master_list,1);
%find the trgger port
for loc_forloop = 1:size_uniquelist
    for loc_forloop1 = 1:size_inp_data
        if strcmp(list(loc_forloop1,1),unique_master_list(loc_forloop,1))
            unique_master_list(loc_forloop,2) = masterlist(loc_forloop1,2);%identifing input signal and bus name
        end
    end
end
loc_f_comeplete_Bus_str = 0;
processed_buses ={};  % Track processed buses
% Initialize variables
% Track processed buses
H = 100; i = 120;      % Initial block positions
cnt_line_num_in = 0;
 

input_bus_height = InputBus_position(4) - InputBus_position(2);

H = 50;  % Initial vertical position (adjust if needed)

processed_buses = {};
cnt_line_num_in = 0;

% ---------- MAIN LOOP ----------
for idx = 1:size(masterlist, 1)

    signal_name = masterlist{idx, 1};
    bus_name    = masterlist{idx, 2};
    signal_type = masterlist{idx, 3};

    % ================= BUS SIGNALS =================
    if strcmp(signal_type, 'Bus') && ~isempty(bus_name)

        if ~ismember(bus_name, processed_buses)

            % Find signals belonging to this bus
            bus_indices = find(strcmp(bus_name, masterlist(:,2)));
            num_bus_signals = length(bus_indices);

            % Create Bus Creator
            bus_creator_name = ['frame_sample/Input Bus/', bus_name, '_creator'];

            add_block('simulink/Signal Routing/Bus Creator', ...
                      bus_creator_name, ...
                      'Position', [650, H, 660, H + 20*num_bus_signals]);

            set_param(bus_creator_name, 'Inputs', num2str(num_bus_signals));

            % ---- Create Inports and connect ----
            for j = 1:num_bus_signals

                sig_idx  = bus_indices(j);
                sig_name = masterlist{sig_idx, 1};

                IB_name = [sig_name, '_in'];
                in_block_path = ['frame_sample/Input Bus/', IB_name];

                add_block('simulink/Commonly Used Blocks/In1', ...
                          in_block_path, ...
                          'Position', [400, H, 430, H+20]);

                line_handle = add_line('frame_sample/Input Bus', [IB_name, '/1'],[bus_name, '_creator/', num2str(j)],'autorouting', 'on');

                set_param(line_handle, 'Name', sig_name);

                H = H + 30;

                % ? Dynamic resizing (safe use of j here)
                if (j > 5) || (idx > 5)
                    input_bus_height = input_bus_height + 5;
                    InputBus_position(4) = InputBus_position(2) + input_bus_height;
                    set_param([model '/Input Bus'], 'Position', InputBus_position);
                end
            end

            % ---- Create Out block ----
            out_block_name = ['frame_sample/Input Bus/', bus_name];

            add_block('simulink/Commonly Used Blocks/Out1', ...
                      out_block_name, ...
                      'Position', [800, H, 830, H+20]);

            % Connect Bus Creator to Out block
            bus_line_handle = add_line('frame_sample/Input Bus', ...
                                      [bus_name, '_creator/1'], ...
                                      [bus_name, '/1'], ...
                                      'autorouting', 'on');

            set_param(bus_line_handle, 'Name', bus_name);

            cnt_line_num_in = cnt_line_num_in + 1;

            processed_buses{end+1} = bus_name;

            H = H + 50;

            % ? IMPORTANT: only idx used here
            if (idx > 5)
                input_bus_height = input_bus_height + 5;
                InputBus_position(4) = InputBus_position(2) + input_bus_height;
                set_param('frame_sample/Input Bus', 'Position', InputBus_position);
            end
        end

    % ================= SCALAR SIGNALS =================
    elseif strcmp(signal_type, 'Scalar') || isempty(bus_name)

        IB_name = [signal_name, '_in'];

        in_block_path  = ['frame_sample/Input Bus/', IB_name];
        out_block_path = ['frame_sample/Input Bus/', signal_name];

        % Create blocks
        add_block('simulink/Commonly Used Blocks/In1', ...
                  in_block_path, ...
                  'Position', [400, H, 430, H+20]);

        add_block('simulink/Commonly Used Blocks/Out1', ...
                  out_block_path, ...
                  'Position', [800, H, 830, H+20]);

        % Connect
        line_handle = add_line('frame_sample/Input Bus', ...
                               [IB_name, '/1'], ...
                               [signal_name, '/1'], ...
                               'autorouting', 'on');

        set_param(line_handle, 'Name', signal_name);

        cnt_line_num_in = cnt_line_num_in + 1;

        H = H + 30;

        % ? Dynamic resizing based only on idx
        if (idx > 5)
            input_bus_height = input_bus_height + 5;
            InputBus_position(4) = InputBus_position(2) + input_bus_height;
             set_param([model '/Input Bus'], 'Position', InputBus_position);
        end
    end
end

% ---------- FINAL RESIZE (IMPORTANT) ----------
pos = get_param([model '/Input Bus'], 'Position');

% Ensure subsystem fits all content
pos(4) = max(pos(4), H + 50);

set_param([model '/Input Bus'], 'Position', pos);
%for Adding data in TestData
TestData_path = [model '/TestData'];
TestData_position = get_param(TestData_path, 'Position');
TestData_height = TestData_position(4) - TestData_position(2);
for loc_for_7 = 1:size_inp_data
    x = x+1;
    temp_data = char(masterlist{x,1});
    %temp_data = temp_data(2:end-1);
    temp_FmWS_name = ['FromWs_',temp_data];
    temp_path_name = ['frame_sample/TestData/',temp_FmWS_name];
    add_block('simulink/Sources/From Workspace',temp_path_name,'position',[140,y,290,z]);
    ZOHN = ['Zero-Order_Hold_',num2str(x)];
    ZOHN1 = [ZOHN,'/1'];
    ZOHN_path = ['frame_sample/',ZOHN];
    add_block('simulink/Discrete/Zero-Order Hold',[fileparts(temp_path_name),'/',ZOHN],'position',[330,y,410,z]);
    ZOHN_Handle = get(gcbh);
    ZOHN_Handle = ZOHN_Handle.Handle;
    set_param(ZOHN_Handle,'ShowName','off');
    %set_param(['frame_sample' '/' 'From'],'Position','Nearest');
    DTC = ['DTC_',num2str(x)];
    DTC1 = [DTC,'/1'];
    DTC_Path = ['frame_sample/',DTC];
    add_block('simulink/Signal Attributes/Data Type Conversion',[fileparts(temp_path_name),'/',DTC],'position',[450,y,500,z]);
    if (strcmp(char(masterlist{x,8}), 'uint8')) || (strcmp(char(masterlist{x,8}), 'int8')) || (strcmp(char(masterlist{x,8}), 'boolean'))
        set_param(temp_path_name, 'OutDataTypeStr', char(masterlist{x,8}))
    end
    DTC_Handle = get(gcbh);
    DTC_Handle = DTC_Handle.Handle;
    set_param(DTC_Handle,'ShowName','off');
    A = get_param(temp_path_name,'Handle');
    temp_variable_name = ['[t,mi',temp_data,']'];
    set_param(A,'VariableName',temp_variable_name);
    add_block('simulink/Commonly Used Blocks/Out1',['frame_sample/TestData/',temp_data],'position',[550,y,600,z]);
    add_line('frame_sample/TestData',[temp_FmWS_name,'/1'],ZOHN1);
    Routing1 = ['TestData/',num2str(x)];
    Routing2 = ['Input Bus/',num2str(x)];
    %set_param('frame_sample','HideAutomaticNames','off')
   
    %set_param(['frame_sample' '/' 'From'],'Position','Nearest')
    add_line('frame_sample/TestData',ZOHN1,DTC1,'autorouting','on');
    add_line('frame_sample/TestData',DTC1,[temp_data,'/1'],'autorouting','on');
    add_line('frame_sample',Routing1,Routing2,'autorouting','on');
    B = find_system('frame_sample/TestData','FindAll','on','type','line');
    set_param(B,'Name',temp_data);
    [y,z,c,d] = feval(@(L) L{:},num2cell([y+30,z+30,c+90,d+90]));
    if (loc_for_7>5)
          
            TestData_height = TestData_height + 5;
            TestData_position(4) = TestData_position(2) + TestData_height;
            set_param(TestData_path, 'Position', TestData_position);

    end
end
% ---------- FINAL RESIZE (IMPORTANT) ----------
pos = get_param(TestData_path, 'Position');

% Ensure subsystem fits all content
pos(4) = max(pos(4), H + 50);

set_param(TestData_path, 'Position', pos);

TestOutput_path = [model '/TestOutput'];
TestOutput_position = get_param(TestOutput_path, 'Position');
TestOutput_height = TestOutput_position(4) - TestOutput_position(2);
[x,y,z,c,d,I] = feval(@(L) L{:},num2cell([0,58,72,473, 487,0]));
for loop_in_testdataoutput = 1:size_outport_data
    temp_outport_data = char(output_master_list{loop_in_testdataoutput,1});
    %temp_data = temp_data(2:end-1);
    temp_ToWS_name = ['ToWs_',temp_outport_data];
    temp_Topath_name = ['frame_sample/TestOutput/',temp_ToWS_name];
    To_workspace_handle = add_block('simulink/Sinks/To Workspace',temp_Topath_name,'position',[2050,y,2200,z]);
    ToWs_variable_name = ['mo',temp_outport_data];
    set_param(To_workspace_handle,'VariableName',ToWs_variable_name);
    add_block('simulink/Commonly Used Blocks/In1',['frame_sample/TestOutput/',temp_outport_data],'position',[140,y,170,z]);
    
    
    testout_name = find_system('frame_sample/TestOutput','FindAll','on','type','line');
    set_param(testout_name,'Name',temp_outport_data);
    DTC_Tows = ['DTC_1_',num2str(loop_in_testdataoutput)];
    DTC2 = [DTC_Tows,'/1'];
    DTC_Tows_Path = ['frame_sample/TestOutput/',DTC_Tows];
    DTC_Handle1 = add_block('simulink/Signal Attributes/Data Type Conversion',DTC_Tows_Path,'position',[260,y,300,z]);
  % add_line('frame_sample/TestOutput',[temp_outport_data,'/1'],[temp_ToWS_name,'/1']);
    add_line('frame_sample/TestOutput',[temp_outport_data,'/1'],DTC2);
    Routing3 = ['TestOutput/',num2str(loop_in_testdataoutput)];
    add_line('frame_sample/TestOutput',DTC2,[temp_ToWS_name,'/1'],'autorouting','on');
    set_param(DTC_Handle1,'ShowName','off');
    [y,z,c,d] = feval(@(L) L{:},num2cell([y+30,z+30,c+30,d+30]));
    if (loop_in_testdataoutput>5)
          
            TestOutput_height = TestOutput_height + 5;
            TestOutput_position(4) = TestOutput_position(2) + TestOutput_height;
            set_param(TestOutput_path, 'Position', TestOutput_position);

    end
end
% ---------- FINAL RESIZE (IMPORTANT) ----------
pos = get_param(TestOutput_path, 'Position');

% Ensure subsystem fits all content
pos(4) = max(pos(4), H + 50);

set_param(TestOutput_path, 'Position', pos);
second_col = output_master_list(:, 2);
% Remove empty entries
second_col = second_col(~cellfun(@isempty, second_col));
% Initialize output cell array
bus_names = {};
% Loop to preserve order and uniqueness
for loop1 = 1:length(second_col)
    current = second_col{loop1};
    if ~any(strcmp(bus_names, current))
        bus_names{end+1} = current; %#ok<AGROW>
    end
end
 
size_Outbus_data = size(bus_names,2);  
for loc_for_21 = 1:size_outport_data
    Outdata = char(output_master_list{loc_for_21,1});
    Out_bus_data = char(output_master_list{loc_for_21,2});
    unique_Outlist = regexprep(Outdata,'\_+\d*$','');
    outlist(loc_for_21,1) = mat2cell(unique_Outlist,1);
end
unique_master_Outlist = unique(outlist(:,1));
size_uniqueOutlist = size(unique_master_Outlist,1);
for loc_loop = 1:size_uniqueOutlist
    for loc_loop1 = 1:size_outport_data
        if strcmp(outlist(loc_loop1,1),unique_master_Outlist(loc_loop,1))
            unique_master_Outlist(loc_loop,2) = output_master_list(loc_loop1,2);%identifing which bus signal related which bus
        end
    end
end
temp_outbus_data = '';
port = 1;
compportnum = 0;
[s,t] = deal(248,262);
loc_f_comeplete_outBus_str = 0;
cnt_line_num_out  = 0;
Line = 1; 
Line_single = 1;
DeMux_name = '';
i=H+30;
% Initialize variables
processed_buses = {};  % keep track of buses already handled
[s, t, H_start] = deal(248, 262, 30); % initial positions for blocks
Line = 1; % line counter for Bus Selector outputs
OutputBus_path = [model '/Output Bus'];
outputBus_position = get_param(OutputBus_path, 'Position');

outputBus_height = outputBus_position(4) - outputBus_position(2);

for idx = 1:size(output_master_list,1)
    signalName = char(output_master_list{idx,1});
    parentBus  = output_master_list{idx,2};
    signalType = output_master_list{idx,3};
    dataType   = output_master_list{idx,4};
    busSize    = output_master_list{idx,5};
    % ----------------------------
    % Case 1: SCALAR
    % ----------------------------
    if strcmp(signalType,'Scalar')
        inBlock  = ['frame_sample/Output Bus/',signalName,'_in'];
        outBlock = ['frame_sample/Output Bus/',signalName];
        add_block('simulink/Commonly Used Blocks/In1', inBlock, ...
                  'Position',[400,H_start,430,H_start+20]);
        add_block('simulink/Commonly Used Blocks/Out1', outBlock, ...
                  'Position',[800,s,830,t]);
        % Connect and name the line
        line_handle = add_line('frame_sample/Output Bus', ...
                               [signalName,'_in/1'], [signalName,'/1'], 'autorouting','on');
        set_param(line_handle, 'Name', signalName);
        cnt_line_num_out = cnt_line_num_out+1;
        H_start = H_start + 30;
        [s,t] = deal(s+30, t+30);
    end
    % ----------------------------
    % Case 2: BUS
    % ----------------------------
    if strcmp(signalType,'Bus') && ~isempty(parentBus)
        % Only process bus once
        if ~ismember(parentBus, processed_buses)
            % Find all signals in this bus
            bus_indices = find(strcmp(parentBus, output_master_list(:,2)));
            num_bus_signals = length(bus_indices);
            % Create Bus Selector block
            busSelectorName = ['frame_sample/Output Bus/', parentBus,'_Sel'];
            add_block('simulink/Signal Routing/Bus Selector', busSelectorName, ...
                      'Position',[650,H_start,660,H_start + 20*num_bus_signals]);
            % Create In1 block for parent bus if it does not exist
            inBlock = ['frame_sample/Output Bus/', parentBus];
            if isempty(find_system('frame_sample/Output Bus','SearchDepth',1,'Name',parentBus))
                add_block('simulink/Commonly Used Blocks/In1', inBlock, 'Position',[400,H_start,430,H_start + 20*num_bus_signals]);
                line_handle = add_line('frame_sample/Output Bus',[parentBus,'/1'],[parentBus,'_Sel/1'], 'autorouting','on');
                set_param(line_handle, 'Name', parentBus);
            end
            % Name Bus Selector outputs after actual signals
            signal_names = cell(1,num_bus_signals);
            for k = 1:num_bus_signals
                sig_idx = bus_indices(k);
                signal_names{k} = char(output_master_list{sig_idx,1});
            end
            set_param(busSelectorName, 'OutputSignals', strjoin(signal_names, ','));
            % Create Out1 blocks for each bus signal
            for j = 1:num_bus_signals
                sig_idx = bus_indices(j);
                sig_name = char(output_master_list{sig_idx,1});
                outBlock = ['frame_sample/Output Bus/', sig_name];
                add_block('simulink/Commonly Used Blocks/Out1', outBlock, ...
                          'Position',[800,s,830,t]);
                 add_line('frame_sample/Output Bus',[parentBus,'_Sel/',num2str(j)], ...
                         [sig_name,'/1'],'autorouting','on');
                s = s + 30; t = t + 30;
                % ? Dynamic resizing (safe use of j here)
                if (j > 5) || (idx > 5)
                    outputBus_height = outputBus_height + 5;
                    outputBus_position(4) = outputBus_position(2) + outputBus_height;
                    set_param([model '/Output Bus'], 'Position', outputBus_position);
                end
            end
              cnt_line_num_out = cnt_line_num_out+1;
            % Mark this bus as processed
            processed_buses{end+1} = parentBus;
            H_start = H_start + 30*num_bus_signals + 20;
        end
    end
 
end
 % ---------- FINAL RESIZE (IMPORTANT) ----------
pos = get_param(OutputBus_path, 'Position');

% Ensure subsystem fits all content

pos(4) = max(pos(4), H + 50);%setting according to input bus height

set_param(OutputBus_path, 'Position', pos);

for loc_for_27 = 1:size_outport_data
    Outbusline = ['Output Bus','/',num2str(loc_for_27)];
    DTCOutline = ['DTC_1_',num2str(loc_for_27),'/1'];
    Routing3 = ['TestOutput/',num2str(loc_for_27)];
    if(loc_for_27 == 55)
        test_pt = 1;
    end
   add_line('frame_sample',Outbusline,Routing3,'autorouting','on');
end
FP = ['frame_sample','/',NM];
copy_frame(BP,fileparts(FP),NM);
for loc_for_28 = 1:cnt_line_num_in
    inbusline = ['Input Bus','/',num2str(loc_for_28)];
    subsysinline = [NM,'_TL','/',num2str(loc_for_28)];
    add_line('frame_sample',inbusline,subsysinline,'autorouting','on');
end
% to find h fucntion block in the sub system and add a constant  to it.
fnd_trgport = find_system([FP,'_TL'],'SearchDepth',1,'BlockType','TriggerPort');
if(~isempty(fnd_trgport))
    %adding a trigger block using constant block
    add_block('simulink/Ports & Subsystems/Function-Call Generator','frame_sample/Function-Call Generator','position',[810,40,840,70]);
    fnd_cnst = char(find_system('frame_sample','FindAll','on','SearchDepth',1,'BlockType','S-Function'));
    if(~isempty(fnd_cnst))
        %adding trigger line to NM 
        add_line('frame_sample','Function-Call Generator/1',[NM,'/trigger'],'autorouting','on');
        set_param('frame_sample/Function-Call Generator','sample_time','-1');
    end    
end
for loc_for_28 = 1:cnt_line_num_out
    outbusline = ['Output Bus','/',num2str(loc_for_28)];
    subsysoutline = [NM,'_TL','/',num2str(loc_for_28)];
    add_line('frame_sample',subsysoutline,outbusline,'autorouting','on');
end
framename = ['Test_Frame_',NM,'_tl.slx'];
[~, name, ~] = fileparts(framename);
bds = find_system('type','block_diagram');
frame_opened = 0;

for k = 1:numel(bds)
    modelName = bds{k};
    if strcmp(modelName, name)
        frame_opened = 1;
        break;
    end
end

if frame_opened
    frame_path = get_param(name, 'FileName');
    choice = questdlg( ...
        'Do you want to open and save new frame or use existing Test frame?', ...
        'Create New Frame', ...
        'Create New Frame', ...
        'Continue with Existing Test Frame', ...
        'Cancel');
    
        if strcmp(choice, 'Cancel')
            return;
        end

        if strcmp(choice, 'Create New Frame')
            save_system(frame_path);
            close_system(frame_path);
            save_system('frame_sample',framename);
            frame_gen_flag = 1;
            
            %current_frame_location= [pwd,'\frame_sample.slx'];
            current_frame_location= [pwd,'\',framename];
            % Define the folder name
            folderName = fullfile(pwd, ['Test_',NM]);
            % Check if the folder exists, and create it if it doesn't
            if ~exist(folderName, 'dir')
                mkdir(folderName);
            end
            % frame_path=fullfile(pwd, ['Test_',framename]);
            % destination_frame_location = [frame_path,'\',framename];
            destination_frame_location = fullfile(pwd, ['Test_',NM]);
            frame_path=destination_frame_location;
            close_system(current_frame_location);
            try
                movefile(current_frame_location,destination_frame_location , 'f');
            catch
                movefile(current_frame_location,destination_frame_location);
            end
            
            open_system([destination_frame_location,'\',framename]);
            final_slx_path = [destination_frame_location,'\',framename];
            return;
        elseif strcmp(choice, 'Continue with Existing Test Frame')
            existing_frame_path = get_param(name, 'FileName');
            frame_sample_path = get_param('frame_sample', 'FileName');
            save_system(frame_sample_path); close_system(frame_sample_path);
            frame_gen_flag = 1;
            final_slx_path = existing_frame_path;
           return;
        end
end

framename = ['Test_Frame_',NM,'_tl.slx'];
save_system('frame_sample',framename);
current_frame_location= [pwd,'\',framename];
folderName = fullfile(pwd, ['Test_',NM]);
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

destination_frame_location = fullfile(pwd, ['Test_',NM]);
frame_path=destination_frame_location;
close_system(current_frame_location);
movefile(current_frame_location,destination_frame_location , 'f');
frame_name_slx = [destination_frame_location,'\',framename];
open_system(frame_name_slx);

frame_gen_flag=1;

final_slx_path =[destination_frame_location,'\',framename];
% scriptFolder = fileparts(mfilename('fullpath'));

% outputs=fullfile(scriptFolder, 'outports.txt');
% inputs=fullfile(scriptFolder, 'inports.txt');
% parameters=fullfile(scriptFolder, 'parameter.txt');
%constants=fullfile(scriptFolder, 'constants.txt');
% paths={outports_file_path, inports_file_path, parameters_file_path};
% destination=frame_path;
%destination=fullfile(frame_path, ['Test_',framename]);
% if ~exist(destination, 'dir')
%     mkdir(destination);
% end
%  
destination = [frame_path,'\',[NM,'_','data']];
if ~exist(destination, 'dir')
    mkdir(destination);
end

frame_info = fullfile(destination, 'frame_info.mat');
save(frame_info, 'final_slx_path', 'frame_gen_flag');
model_info=fullfile(destination, 'model_info.mat');
save(model_info, 'main_model_name', 'frame_model_path', 'frame_path');

% for k = 1:numel(paths)
%     if ~exist(fullfile(destination,'outports.txt'), 'file')
%         copyfile(paths{k}, destination);
%     end
%     copyfile(paths{k}, destination, 'f');
% end
%output_busupdated();
end


function copy_frame(subsystemPath,newModel,NA)
    var = NA ;
    targetlink_subsystem_name=[var,'_TL'];
    FP = [newModel '/',targetlink_subsystem_name];
    add_block('tllib/Subsystem',FP,'position',[400 100 500 200]);
    %  COPY SUBSYSTEM INTO NEW MODEL
    dstBlock = FP;
    open_system(dstBlock);
    %search =
    %% Find Inport & Outport blocks
    inports  = find_system(gcs, 'SearchDepth', 1, 'BlockType', 'Inport');
    outports = find_system(gcs, 'SearchDepth', 1, 'BlockType', 'Outport');
    %% Delete them
    for i = 1:length(inports)
        delete_block(inports{i});
    end
    for i = 1:length(outports)
        delete_block(outports{i});
    end
    %% Save the model
    FP=[gcs, '/',var];
    add_block(subsystemPath,FP,'position',[1150,102,1430,218]);
    % Add Function-Call Generator block to the model
      funcCallGenPath = [fileparts(FP), '/FunctionCallGenerator'];
    add_block('simulink/Ports & Subsystems/Function-Call Generator', funcCallGenPath, 'MakeNameUnique', 'on','Position', [1190 -5 1230 25]);
    set_param(funcCallGenPath, 'sample_time', '0.01');
    subsysPath_Fun=FP;
    ph_funcCallGen = get_param(funcCallGenPath, 'PortHandles');
    %set_param(ph_funcCallGen, 'Sample time', '0.01');
    ph_subsys = get_param(subsysPath_Fun, 'PortHandles');
    % Connect output of Function-Call Generator to first function-call input port of the subsystem
    add_line(fileparts(FP), ph_funcCallGen.Outport, ph_subsys.Trigger, 'autorouting', 'on');
    %open_system(dstBlock);
    %FP=[FP,'/',var];
    count_in=1;
    fnd_in_port = find_system(FP, 'FindAll', 'on', 'SearchDepth', 1, 'BlockType', 'Inport');
    inputs=cell(length(fnd_in_port),1);
    for i = 1:length(fnd_in_port)
        inputs{count_in, 1} = get_param(fnd_in_port(i), 'Name');
        count_in=count_in+1;
    end
    count_out=1;
    fnd_out_port = find_system(FP, 'FindAll', 'on', 'SearchDepth', 1, 'BlockType', 'Outport');
    outputs=cell(length(fnd_out_port),1);
    for i = 1:length(fnd_out_port)
        outputs{count_out, 1} = get_param(fnd_out_port(i), 'Name');
        count_out=count_out+1;
    end
    % ======== The three backward steps (MINIMAL CHANGE) ========
    subsysPath=FP;
    FP=get_param(FP,'Parent');
    addInOutPorts(FP, subsysPath, inputs, outputs);
    FP=get_param(FP,'Parent');
    subsysPath=[FP, '/',targetlink_subsystem_name];
    addInOutPorts(FP, subsysPath, inputs, outputs);
    FP=get_param(FP,'Parent');
    subsysPath=[FP,'/','Subsystem'];
    addInOutPorts(FP, subsysPath, inputs, outputs);
    % ===========================================================
    %% ===============================
    %  SAVE NEW MODEL
    % ===============================
    save_system(newModel);
    disp('Subsystem + TargetLink Main Dialog added successfully.');
end

function addInOutPorts(FP, subsysPath, inputs, outputs)
    x_start = 30; % X coordinate for Inports
    y_start = 30; % Starting Y coordinate for first Inport
    y_spacing = 40;
    n = 1;
    if n>=1
        % ===== CHANGED: robust detection and parent normalization =====
        % Normalize FP in case we're at model root (Parent == '')
        if isempty(FP)
            FP = bdroot(subsysPath);                      %% CHANGED
        end
        % Ensure model is loaded (prevents intermittent misses)
        mdl = bdroot(FP);                                 %% CHANGED
        if ~bdIsLoaded(mdl), load_system(mdl); end        %% CHANGED
        % Robustly find existing Inports/Outports at this level
        inports  = find_system(FP, 'SearchDepth', 1, ...  %% CHANGED
            'LookUnderMasks','all', 'FollowLinks','on', ...
            'BlockType', 'Inport');
        outports = find_system(FP, 'SearchDepth', 1, ...  %% CHANGED
            'LookUnderMasks','all', 'FollowLinks','on', ...
            'BlockType', 'Outport');
        inLines  = get_param(inports,  'LineHandles');   % returns cell array of structs (usually)
        outLines = get_param(outports, 'LineHandles');
   
        %% Delete them
        for i = 1:length(inports)
            % Handle both cases: inLines may be a struct (single) or cell array (multiple)
            if iscell(inLines)
                lh = inLines{i};
            else
                lh = inLines; % single block case
            end
            % Inport blocks connect from their Outport
            if isfield(lh,'Outport') && ~isempty(lh.Outport)
                % lh.Outport may be scalar handle or vector (branches)
                h = lh.Outport;
                h = h(h ~= -1);           % remove invalid handles
                if ~isempty(h)
                    delete_line(h);       % delete connected line(s)
                end
            end
            % Now delete the block itself
            delete_block(inports{i});
        end
        %% Delete lines + Outport blocks
        for i = 1:length(outports)
            if iscell(outLines)
                lh = outLines{i};
            else
                lh = outLines; % single block case
            end
            % Outport blocks connect into their Inport
            if isfield(lh,'Inport') && ~isempty(lh.Inport)
                h = lh.Inport;
                h = h(h ~= -1);
                if ~isempty(h)
                    delete_line(h);
                end
            end
            delete_block(outports{i});
        end
        n = n-1;
    end
    for i = 1:numel(inputs)
        inportName = inputs{i};
        inportBlock = [FP '/' inportName];
        add_block('simulink/Sources/In1', inportBlock, ...
            'Position', [x_start, y_start+(i-1)*y_spacing, x_start+30, y_start+20+(i-1)*y_spacing]);
        set_param(inportBlock, 'Name', inportName);
        % Connect Inport to subsystem
        ph_inport = get_param(inportBlock, 'PortHandles');
        ph_subsys = get_param(subsysPath, 'PortHandles');
        add_line(FP, ph_inport.Outport, ph_subsys.Inport(i), 'autorouting', 'on');
    end

    module_pos = get_param(subsysPath,'Position'); % [left top right bottom]
    module_right_x = module_pos(3);
    module_top_y = module_pos(2);
    x_out_start = module_right_x + 50; % 50 pixels to the right
    y_out_start = module_top_y + 10;   % 10 pixels below top
    y_out_spacing = 30;
    for i = 1:numel(outputs)
        outportName = outputs{i};
        outportBlock = [FP '/' outportName];
        add_block('simulink/Sinks/Out1', outportBlock, ...
            'Position', [x_out_start, y_out_start+(i-1)*y_out_spacing, x_out_start+30, y_out_start+20+(i-1)*y_out_spacing]);
        set_param(outportBlock, 'Name', outportName);
        % Connect subsystem output port i to Outport block
        ph_outport = get_param(outportBlock, 'PortHandles');
        ph_subsys = get_param(subsysPath, 'PortHandles');
        add_line(FP, ph_subsys.Outport(i), ph_outport.Inport, 'autorouting', 'on');
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

function move_data_files_to_destination(file, destination_path)
    movefile(file, destination_path)
end
