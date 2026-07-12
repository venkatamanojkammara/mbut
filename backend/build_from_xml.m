% ******************************************************************************
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
% *****************************************************************************
%
%  Created  on  :  26-03-2020
%  Author       :  Venkata Manoj Kammara
%  Department   :  IDSI
%  File         :  build_from_xml.m
%
%  Description  :  Generate .mat files from Test Cases XML file for simulation
%
% *****************************************************************************
function outDir = build_from_xml(xml_path, timestep, data_folder_Paths)
    fig = resolveGuiFig();    
    
    logFile = fullfile(fileparts(xml_path), 'commandLog.txt');
    doc = xmlread(xml_path);
    outDir = fileparts(xml_path);
    
    setStatus(fig, 'Extracting the Test Cases Data...');
    commandLog(logFile, 'Started extracting the Test Cases data from XML...');
    
    testCases = doc.getElementsByTagName('test-case');
   
    for r = 0:testCases.getLength-1
        tc = testCases.item(r);
        ts_name = char(tc.getAttribute('test-case-id'));
        init_block = sprintf('// initialization\n');
        initNode = tc.getElementsByTagName('initial-values').item(0);
        
        if ~isempty(initNode)
            nodes = initNode.getElementsByTagName('init-value');
            for i = 0:nodes.getLength-1
                n = nodes.item(i);
                init_block = [init_block sprintf('%s=%s;\n',char(n.getAttribute('name')),char(n.getAttribute('value')))];
            end
        end

        % --- INSIDE build_from_xml(), replace action_block loop only ---

		action_block = '';
		seq = tc.getElementsByTagName('test-sequence').item(0);

		if ~isempty(seq)

			nodes = seq.getChildNodes;

			for i = 0:nodes.getLength-1

				n = nodes.item(i);
				if n.getNodeType ~= 1, continue; end

				tag = char(n.getNodeName);

				% ================= INPUT =================
				if strcmp(tag,'test_input')

					type = char(n.getAttribute('type'));

					name = char(n.getAttribute('name'));
					val  = char(n.getAttribute('value'));

					if isempty(type)
						action_block = [action_block sprintf('%s=%s;\n', name, val)];
					end

					% RAMP INPUT
					if strcmp(type,'ramp')
						step = char(n.getAttribute('step_value'));

						action_block = [action_block sprintf('// ramp input\n')];
						action_block = [action_block sprintf('%s=%s; %% step=%s\n', ...
							name, val, step)];
					end
				end

				% ================= OUTPUT =================
				if strcmp(tag,'test_output')

					type = char(n.getAttribute('type'));
					name = char(n.getAttribute('name'));
					val  = char(n.getAttribute('value'));

					if isempty(type)

						action_block = [action_block sprintf('\\ expected output\n')];

						tol = char(n.getAttribute('tolerance'));
						if ~isempty(tol)
							action_block = [action_block sprintf('[Tolerance=%s]\n',tol)];
						end

						action_block = [action_block sprintf('%s=%s;\n', name, val)];
					end

					% RAMP OUTPUT
					if strcmp(type,'ramp')

						step = char(n.getAttribute('step_value'));
						tol  = char(n.getAttribute('tolerance'));

						action_block = [action_block sprintf('\\ ramp expected output\n')];

						if ~isempty(tol)
							action_block = [action_block sprintf('[Tolerance=%s]\n', tol)];
						end

						action_block = [action_block sprintf('%s=%s; %% step=%s\n', ...
							name, val, step)];
					end
				end

				% WAIT
				if strcmp(tag,'test_wait')
					ms = str2double(regexprep(char(n.getAttribute('time')),'ms',''));
					action_block = [action_block sprintf('[+%gms]\n',ms)];
				end

			end
		end

        % RAW STRUCT
        raw = cell(3,7);
        raw{3,1} = ts_name;
        raw{3,6} = init_block;
        raw{3,7} = action_block;

        process_single_ts(raw, timestep, data_folder_Paths, outDir);
        setStatus(fig, ['Loaded ',ts_name, '.mat', '...']);
        commandLog(logFile, ['Loaded ',ts_name, '.mat', '...']);
        sprintf('Loaded %s', ts_name);
    end
    
    setStatus(fig, 'Ready');
    commandLog(logFile, 'Test Cases data loaded succesfully into .mat files');
    fprintf('[DONE] XML -> MAT complete\n');

    try
        setStatus(fig, 'Splitting the .mat files to TS_0xx...')
        commandLog(logFile, 'Started splitting the .mat files to TS_0xx...');
        create_mtcd_split_files_impl(outDir);
        commandLog(logFile, 'Splitting the .mat files to TS_0xx is done !');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error : ' ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Warning');
    end

    try
        setStatus(fig, 'Extracting Initial Values from TS_0xx...')
        commandLog(logFile, 'Started extracting Initial Values from TS_0xx...');
        export_initial_values_from_xml(xml_path);
        commandLog(logFile, 'Extracting Initial Values from TS_0xx is done !');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error : ' ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Warning');
    end

    try
        setStatus(fig, 'Extracting Test Case Specifications...');
        commandLog(logFile, 'Started extracting Test Case Specifications...');
        process_full_xml(xml_path);
        commandLog(logFile, 'Extracting Test Case Specifications is done !');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error : ' ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Warning');
    end


    srcDir = fileparts(xml_path);
    destDir = fullfile(fileparts(xml_path), 'mat_file');
    try
        setStatus(fig, 'Moving TS_0xx .mat fiels...');
        commandLog(logFile, 'Started moving TS_0xx .mat fiels...');
        move_ts_mat_files(srcDir, destDir);
        commandLog(logFile, 'Moving TS_0xx .mat fiels is done !');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error : ' ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Warning');
    end

    try
        setStatus(fig, 'Extracting Requirements Data from XML...');
        commandLog(logFile, 'Started extracting Requirements Data from XML...');
        xml_to_mat_requirements(xml_path);
        commandLog(logFile, 'Extracting Requirements Data from XML is done !');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error : ' ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Warning');
    end
    
    try
        setStatus(fig, 'Pushing all Inputs & Parameters to Base Workspace');
        commandLog(logFile, 'Pushing all Inputs & Parameters to Base Workspace');
        load_config_to_workspace(data_folder_Paths);
        commandLog(logFile, 'Pushing all Inputs & Parameters to Base Workspace is done');
        setStatus(fig, 'Ready');
    catch ME
        setStatus(fig, ['Error : ' ME.message]);
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Warning');
    end
    setStatus(fig, 'Ready');
end

function create_mtcd_split_files_impl(dirPath)
    fig = resolveGuiFig();
    setStatus(fig,'Loading I/O for Test Cases...');
    
    if nargin < 1 || ~(ischar(dirPath) || isstring(dirPath))
        error('Usage: create_mtcd_split_files_impl(dirPath)');
    end
    
    dirPath = char(dirPath);
    if ~hasFolder(dirPath)
        error('Source directory not found: %s', dirPath);
    end

    destRoot = dirPath;

    SUF_EXPECTED = '_expected_output.mat';
    SUF_TEST     = '_test_data.mat';
    SUF_TEMP     = '_test_data_temp.mat';

    srcFiles = dir(fullfile(dirPath, '*.mat'));
    if isempty(srcFiles)
        fprintf('[INFO] No .mat files found in %s\n', dirPath);
        return;
    end

    for i = 1:numel(srcFiles)
        fname = srcFiles(i).name;

        if endsWithi(fname, SUF_EXPECTED) || endsWithi(fname, SUF_TEST) || endsWithi(fname, SUF_TEMP)
            fprintf('[SKIP] %s (already a split output)\n', fname);
            continue;
        end

        fpath = fullfile(dirPath, fname);
        try
            S = load(fpath);
        catch ME
            fprintf(2, '[ERROR] Failed to load %s: %s\n', fpath, ME.message);
            continue;
        end

        hasInputs  = isfield(S, 'struct_all_inputs');
        hasOutputs = isfield(S, 'struct_all_expected_outputs');
        if ~(hasInputs || hasOutputs)
            fprintf('[WARN] %s does not contain expected variables. Skipping.\n', fname);
            continue;
        end

        base = fname;
        if endsWithi(base, '.mat'), base = base(1:end-4); end
        subdir = fullfile(destRoot, base);
        if ~hasFolder(subdir)
            mkdir(subdir);
        end

        out_expected = fullfile(subdir, [base, SUF_EXPECTED]);
        out_test     = fullfile(subdir, [base, SUF_TEST]);
        out_temp     = fullfile(subdir, [base, SUF_TEMP]);

        outputs_top = struct();
        t_exp = [];

        if hasInputs && ~isempty(fieldnames(S.struct_all_inputs))
            in_names = fieldnames(S.struct_all_inputs);
            ref_in = in_names{1};
            t_exp  = safe_get_timestep(S.struct_all_inputs.(ref_in));
        end

        if hasOutputs && ~isempty(fieldnames(S.struct_all_expected_outputs))
            out_names = fieldnames(S.struct_all_expected_outputs);
            if isempty(t_exp)
                ref_out = out_names{1};
                t_exp = safe_get_timestep(S.struct_all_expected_outputs.(ref_out));
            end

            for oi = 1:numel(out_names)
                nm = out_names{oi};
                T  = S.struct_all_expected_outputs.(nm);
                outputs_top.(sanitizeVarName(nm)) = table_value_enable_tolerance(T);
            end
        end
        
        inputs_top = struct();  
        t_td = [];              

        if hasInputs && ~isempty(fieldnames(S.struct_all_inputs))
            in_names = fieldnames(S.struct_all_inputs);
            ref_in   = in_names{1};
            t_td = safe_get_timestep(S.struct_all_inputs.(ref_in));

            for ii = 1:numel(in_names)
                nm  = in_names{ii}; 
            end
            for ii = 1:numel(in_names)
                nm  = in_names{ii};
                Tin = S.struct_all_inputs.(nm);
                valVec = extract_input_numeric(Tin);
                varName = sanitizeVarName(nm);
                inputs_top.(varName) = valVec;
            end
        end

        inputs_top_temp = struct();
        t_tdt = t_td;

        if hasInputs && ~isempty(fieldnames(S.struct_all_inputs))
            in_names = fieldnames(S.struct_all_inputs);
            for ii = 1:numel(in_names)
                nm  = in_names{ii};
                Tin = S.struct_all_inputs.(nm);
                valVec = extract_input_numeric(Tin);      
                rawVar = ['mi' nm];                     
                varName = sanitizeVarName(rawVar);
                inputs_top_temp.(varName) = valVec;
            end
        end

        try
            save(out_expected, '-struct', 'outputs_top', '-v7');
            t = t_exp; %#ok<NASGU>
            save(out_expected, 't', '-append');

            % 2) test_data: explode input DOUBLE VECTORS as top-level vars + t (vector)
            save(out_test, '-struct', 'inputs_top', '-v7');
            t = t_td; %#ok<NASGU>
            save(out_test, 't', '-append');

            % 3) test_data_temp: explode mi<input> DOUBLE VECTORS + t (vector)
            save(out_temp, '-struct', 'inputs_top_temp', '-v7');
            t = t_tdt; %#ok<NASGU>
            save(out_temp, 't', '-append');

            fprintf('[OK]  %s ? %s/: %s, %s, %s\n', fname, base, ...
                [base, SUF_EXPECTED], [base, SUF_TEST], [base, SUF_TEMP]);

        catch ME
            fprintf(2, '[ERROR] Saving split files for %s failed: %s\n', fname, ME.message);
        end
    end
    
    fprintf('[DONE] Processed %d file(s) into %s\n', numel(srcFiles), destRoot);
    setStatus(fig,'Ready');
end

function save_Back2Back_tolerances_xml(xml_path, matFilePath)

    doc = xmlread(xml_path);
    tolNodes = doc.getElementsByTagName('back2back-tolerance');

    dataStruct = struct();

    for i = 0:tolNodes.getLength-1
        n = tolNodes.item(i);
        varName = strtrim(char(n.getAttribute('name')));
        tolStr  = strtrim(char(n.getAttribute('tolerance')));
        if isempty(varName)
            continue
        end
        varName = matlab.lang.makeValidName(varName);
        valueNum = str2double(tolStr);
        if ~isnan(valueNum)
            dataStruct.(varName) = valueNum;
        end
    end
    save(matFilePath, '-struct', 'dataStruct');
end

function export_requirements_xml(xml_path)

    doc = xmlread(xml_path);
    testCases = doc.getElementsByTagName('test-case');
    [xml_dir,~,~] = fileparts(xml_path);

    for r = 0:testCases.getLength-1
        tc = testCases.item(r);
        ts_name = char(tc.getAttribute('test-case-id'));
        reqNode = tc.getElementsByTagName('test-requirements').item(0);
        requirements = {};

        if ~isempty(reqNode)
            nodes = reqNode.getElementsByTagName('requirement');

            for i = 0:nodes.getLength-1
                id = strtrim(char(nodes.item(i).getAttribute('id')));
                if ~isempty(id)
                    requirements{end+1} = id; %#ok<AGROW>
                end
            end
        end

        ts_folder = fullfile(xml_dir, ts_name);
        if ~exist(ts_folder,'dir'), mkdir(ts_folder); end

        fid = fopen(fullfile(ts_folder,[ts_name '_requirements.txt']),'w');

        for i=1:numel(requirements)
            fprintf(fid,'%s\n',requirements{i});
        end

        fclose(fid);

    end
end

function export_initial_values_from_xml(xml_path)
    doc = xmlread(xml_path);
    testCases = doc.getElementsByTagName('test-case');
    [xml_dir,~,~] = fileparts(xml_path);

    for r = 0:testCases.getLength-1
        tc = testCases.item(r);
        ts_name = char(tc.getAttribute('test-case-id'));
        Svars = struct();
        initNode = tc.getElementsByTagName('initial-values').item(0);
        if ~isempty(initNode)
            nodes = initNode.getElementsByTagName('init-value');
            for i = 0:nodes.getLength-1
                n = nodes.item(i);
                name = matlab.lang.makeValidName(char(n.getAttribute('name')));
                val  = str2double(char(n.getAttribute('value')));
                if ~isnan(val)
                    Svars.(name) = val;
                end
            end
        end

        ts_folder = fullfile(xml_dir, ts_name);
        if ~exist(ts_folder,'dir')
            mkdir(ts_folder);
        end

        jsonStruct = struct('name', {}, 'value', {}, 'datatype', {});
        fn = fieldnames(Svars);
        for i=1:numel(fn)
            jsonStruct(end+1) = struct( ...
                'name', fn{i}, ...
                'value', Svars.(fn{i}), ...
                'datatype', 'double');
        end
        
        if isempty(jsonStruct)
            formattedText = '{}';
        else
            rawJson = jsonencode(jsonStruct);
            rawJson = strrep(rawJson, '\/', '/');
            rawJson = rawJson(2:end-1);
            parts = regexp(rawJson, '\},\{', 'split');
            formattedText = ['[' sprintf('\n')];
            for k = 1:length(parts)
                part = parts{k};

                if length(parts)==1
                     part = ['{', part, '}'];
                else
                    if k == 1
                        part = [part, '}'];
                    elseif k == length(parts)
                        part = ['{', part];
                    else
                        part = ['{', part, '}'];
                    end
                end
                formattedText = [formattedText, '  ', strtrim(part)];
                if k < length(parts)
                    formattedText = [formattedText, ',', sprintf('\n')];
                else
                    formattedText = [formattedText, sprintf('\n')];
                end
            end
            formattedText = [formattedText, ']'];
        end
        jsonFileName = fullfile(ts_folder, [ts_name '_changing_parameters.json']);
        fid = fopen(jsonFileName,'w');
        fprintf(fid,'%s',formattedText);
        fclose(fid);
    end
end

function export_ts_conditions_xml(xml_path)
    doc = xmlread(xml_path);
    testCases = doc.getElementsByTagName('test-case');
    [xml_dir,~,~] = fileparts(xml_path);

    for r = 0:testCases.getLength-1
        tc = testCases.item(r);
        ts_name = char(tc.getAttribute('test-case-id'));
        desc = get_attr(tc,'test-case-description');
        spec = get_attr(tc,'test-specifications');
        pre  = get_attr(tc,'preconditions');
        pass = get_attr(tc,'pass-conditions');
        ts_folder = fullfile(xml_dir, ts_name);
        
        if ~exist(ts_folder,'dir')
            mkdir(ts_folder)
        end

        write_txt(ts_folder,ts_name,'description',desc);
        write_txt(ts_folder,ts_name,'test_specification',spec);
        write_txt(ts_folder,ts_name,'preconditions',pre);
        write_txt(ts_folder,ts_name,'pass_conditions',pass);
    end
end

function val = get_attr(parent, tag)
    node = parent.getElementsByTagName(tag).item(0);
    if isempty(node)
        val = '';
    else
        val = char(node.getAttribute('description'));
    end
end

function write_txt(folder, ts_name, suffix, textData)
    fid = fopen(fullfile(folder,[ts_name '_' suffix '.txt']),'w');
    lines = regexp(textData,'\r\n|\n|\r','split');
    for i=1:numel(lines)
        L = strtrim(lines{i});
        if ~isempty(L)
            fprintf(fid,'%s\n',L);
        end
    end
    fclose(fid);
end

function process_full_xml(xml_path)
    [xml_dir,~,~] = fileparts(xml_path);
    try
        export_requirements_xml(xml_path);
    catch ME
        msgbox(ME.message, 'Warning');
    end

    try
        export_ts_conditions_xml(xml_path);
    catch ME
        msgbox(ME.message, 'Warning');
    end

    dataPath = dir(fullfile(xml_dir, '*_data'));
    matFilePath = fullfile([dataPath.folder, '\', dataPath.name], 'back2back_tolerances.mat');
    try
        save_Back2Back_tolerances_xml(xml_path, matFilePath);
    catch ME
        msgbox(ME.message, 'Warning');
    end

    fprintf('\n? FULL XML PROCESSING COMPLETED\n');
end

function process_single_ts(raw, timestep, data_folder_Paths, outDir)
	ramp_inputs = struct();
	ramp_outputs = struct();
	
    ts_name = char(raw{3,1});
    if iscell(data_folder_Paths)
        basePath = data_folder_Paths{1};
    else
        basePath = data_folder_Paths;
    end

    % INPORTS
    fid = fopen(fullfile(basePath,'inports.json'));
    if fid == -1, error('inports.json not found'); end
    rawText = fread(fid,'*char')';
    fclose(fid);
    rawText = strtrim(rawText);
    if rawText(1)=='{', rawText = rawText(2:end); end
    if rawText(end)=='}', rawText = rawText(1:end-1); end
    rawText = ['[', rawText, ']'];

    try
        data = jsondecode(rawText);
    catch
        error('Invalid inports.json format');
    end

    inports = {};
    for i = 1:length(data)
        if isfield(data(i),'signal')
            inports{end+1} = strtrim(data(i).signal); %#ok<AGROW>
        end
    end

    is_input = @(nm) any(strcmp(nm,inports));

    % OUTPORTS (FROM JSON)
    fid = fopen(fullfile(basePath,'outports.json'));
    if fid == -1, error('outports.json not found'); end
    rawText = fread(fid,'*char')';
    fclose(fid);
    rawText = strtrim(rawText);
    if rawText(1)=='{', rawText = rawText(2:end); end
    if rawText(end)=='}', rawText = rawText(1:end-1); end
    rawText = ['[', rawText, ']'];

    try
        data = jsondecode(rawText);
    catch
        error('Invalid outports.json format');
    end

    outports = {};
    for i = 1:length(data)
        if isfield(data(i),'signal')
            outports{end+1} = strtrim(data(i).signal); %#ok<AGROW>
        end
    end

    outports = outports(~cellfun(@isempty,outports));
    is_output = @(nm) any(strcmp(nm,outports));

    % INIT INPUTS
    lines = regexp(char(raw{3,6}),'\n','split');
    curr_in = struct();

    for i=1:numel(lines)
        L = strtrim(lines{i});
        if contains(L,'=')
            [nm,rhs] = split_assignment(L);
            if is_input(nm)
                v = str2double(rhs); if isnan(v), v = 0; end
                curr_in.(nm) = v;
            end
        end
    end

    for i=1:numel(inports)
        if ~isfield(curr_in,inports{i})
            curr_in.(inports{i}) = 0;
        end
    end

    % INIT TABLES
    struct_all_inputs = struct();
    struct_all_expected_outputs = struct();

    fn = fieldnames(curr_in);
    for i=1:numel(fn)
        struct_all_inputs.(fn{i}) = table(0,{curr_in.(fn{i})}, ...
            'VariableNames',{'timestep','value'});
    end

    for i=1:numel(outports)
        nm = outports{i};
        struct_all_expected_outputs.(nm) = table( ...
            0,{0},false,0,...
            'VariableNames',{'timestep','value','is_enable','tolerance'});
    end

    curr_out = struct();
    curr_tol = struct();
    used_outputs = {};
    k = 0;

    action = char(raw{3,7});
    segments = regexp(action,'\[\+[\d\.]+ms\]','split');
    waits = regexp(action,'\[\+([\d\.]+)ms\]','tokens');
    waits = cellfun(@(x)str2double(x{1}),waits);
    steps = round(waits/(timestep*1000));

    in_expected = false;
    active_tol = 0;

    for seg=1:numel(segments)

        lines = regexp(segments{seg},'\n','split');

        for i=1:numel(lines)

            L = strtrim(lines{i});
            if isempty(L), continue; end

            if contains(lower(L),'expected output')
                in_expected = true;
                active_tol = 0;
                continue;
            end

            tok = regexp(L,'\[Tolerance=([^\]]+)\]','tokens');
            if ~isempty(tok)
                tmp = str2double(tok{1}{1});
                if ~isnan(tmp)
                    active_tol = tmp;
                else
                    active_tol = 0;
                end
                continue;
            end

            if contains(L,'=')

				[nm,rhs] = split_assignment(strip_trailing_semicolon(L));

				val = str2double(rhs);
				if isnan(val), val = 0; end

				% Detect ramp step
				tok = regexp(L, 'step\s*=\s*([\d\.\-]+)', 'tokens');

				if ~isempty(tok)
					step_val = str2double(tok{1}{1});
				else
					step_val = [];
				end

				if is_input(nm)

					curr_in.(nm) = val;

					if ~isempty(step_val)
						ramp_inputs.(nm) = step_val;
					end

				elseif is_output(nm)

					curr_out.(nm) = val;

					if ~any(strcmp(nm,used_outputs))
						used_outputs{end+1} = nm;
					end

					if in_expected
						curr_tol.(nm) = active_tol;
						active_tol = 0;
					end

					if ~isempty(step_val)
						ramp_outputs.(nm) = step_val;
					end
				end
			end
        end

        % WAIT
        if seg <= numel(steps)
            nSteps = steps(seg);
        else
            nSteps = 0;
        end

        for s=1:nSteps

			k = k + 1;
			t = round(k*timestep,12);

			% INPUTS
			fn = fieldnames(curr_in);

			for i=1:numel(fn)

				nm = fn{i};

				% APPLY RAMP INPUT
				if isfield(ramp_inputs, nm)
					curr_in.(nm) = curr_in.(nm) + ramp_inputs.(nm);
				end

				struct_all_inputs.(nm) = [ ...
					struct_all_inputs.(nm);
					{t,{curr_in.(nm)}}
				];
			end

			% OUTPUTS
			for i=1:numel(outports)

				nm = outports{i};

				if isfield(curr_out,nm)

					% APPLY RAMP OUTPUT
					if isfield(ramp_outputs, nm)
						curr_out.(nm) = curr_out.(nm) + ramp_outputs.(nm);
					end

					val = curr_out.(nm);

				else
					val = struct_all_expected_outputs.(nm).value{end};
				end

				tol = struct_all_expected_outputs.(nm).tolerance(end);

				if isfield(curr_tol,nm)
					tol = curr_tol.(nm);
				end

				is_en = isfield(curr_out,nm);

				row = table(t,{val},is_en,tol, ...
					'VariableNames',{'timestep','value','is_enable','tolerance'});

				struct_all_expected_outputs.(nm) = ...
					[struct_all_expected_outputs.(nm); row];
			end
		end
    end

    % KEEP ONLY USED OUTPUTS
    struct_expected_outputs = struct();
    for i=1:numel(used_outputs)
        nm = used_outputs{i};
        struct_expected_outputs.(nm) = struct_all_expected_outputs.(nm);
    end

    struct_all_expected_outputs = struct_expected_outputs;
    save(fullfile(outDir,[ts_name,'.mat']),'struct_all_inputs','struct_all_expected_outputs');
end

function s = strip_trailing_semicolon(s)
    s = strtrim(s);
    if ~isempty(s) && s(end) == ';'
        s = s(1:end-1);
    end
end

function [nm, rhs] = split_assignment(line)
    idx = strfind(line, '=');
    if isempty(idx)
        nm = strtrim(line);
        rhs = '';
    else
        nm  = strtrim(line(1:idx(1)-1));
        rhs = strtrim(line(idx(1)+1:end));
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

function tf = hasFolder(p)
    tf = exist(p,'dir') == 7;
end

function tf = endsWithi(str, pat)
    str = char(str); pat = char(pat);
    if length(str) < length(pat)
        tf = false; return;
    end
    tf = strcmpi(str(end-length(pat)+1:end), pat);
end

function t = safe_get_timestep(T)
    t = [];
    if istable(T)
        vnames = T.Properties.VariableNames;
        if any(strcmp(vnames,'timestep'))
            t = T.timestep;
        end
    end
    if ~isempty(t)
        t = t(:);
    end
end

function Tbl = table_value_enable_tolerance(T)
    if ~istable(T)
        Tbl = table(cell(0,1), false(0,1), zeros(0,1),'VariableNames', {'value','is_enable','tolerance'});
        return;
    end

    vnames = T.Properties.VariableNames;
    hasVal = any(strcmp(vnames,'value'));
    hasEn  = any(strcmp(vnames,'is_enable'));
    hasTol = any(strcmp(vnames,'tolerance'));
    n = height(T);
    
    if hasVal
        vals = T.value;
    else
        vals = cell(n,1);
        for i = 1:n, vals{i} = []; end
    end

    if hasEn
        ens = T.is_enable;
        if ~islogical(ens), ens = logical(ens); end
        ens = ens(:);
    else
        ens = false(n,1);
    end

    if hasTol
        tols = double(T.tolerance(:));
    else
        tols = zeros(n,1);
    end
    Tbl = table(vals, ens, tols, 'VariableNames', {'value','is_enable','tolerance'});
end

function valVec = extract_input_numeric(T)
    if istable(T) && any(strcmp(T.Properties.VariableNames,'value'))
        valVec = cells_to_double(T.value);
    else
        valVec = nan(0,1);
    end
end

function v = sanitizeVarName(raw)
    raw = char(raw);
    v = regexprep(raw, '[^A-Za-z0-9_]', '_');
    if isempty(v) || ~isletter(v(1))
        v = ['x_' v];
    end
end

function vec = cells_to_double(cellCol)
    n = numel(cellCol);
    vec = nan(n,1);
    for k = 1:n
        v = cellCol{k};
        if isnumeric(v) && isscalar(v)
            vec(k) = v;
        elseif islogical(v) && isscalar(v)
            vec(k) = double(v);
        elseif ischar(v) || isstring(v)
            vv = str2double(char(v));
            if ~isnan(vv)
                vec(k) = vv;
            else
                vec(k) = NaN;
            end
        else
            vec(k) = NaN;
        end
    end
end

function move_ts_mat_files(srcDir, destDir)
    if ~exist(srcDir, 'dir')
        error('Source directory does not exist: %s', srcDir);
    end

    if ~exist(destDir, 'dir')
        mkdir(destDir);
    end

    files = dir(fullfile(srcDir, 'TS_*.mat'));
    if isempty(files)
        fprintf('No TS_*.mat files found in: %s\n', srcDir);
        return;
    end

    for i = 1:numel(files)
        srcFile = fullfile(srcDir, files(i).name);
        destFile = fullfile(destDir, files(i).name);
        try
            movefile(srcFile, destFile);
            fprintf('[OK] Moved: %s\n', files(i).name);
        catch ME
            warning('Failed to move %s: %s', files(i).name, ME.message);
        end
    end
    fprintf('? All TS MAT files moved to: %s\n', destDir);
end

function xml_to_mat_requirements(xmlPath)
    try
        fprintf('Loading XML: %s\n', xmlPath);
        doc = xmlread(xmlPath);
        headerList = doc.getElementsByTagName('header');
        if headerList.getLength == 0
            error('No <header> tag found.');
        end

        headerNode = headerList.item(0);
        reqDetailsList = headerNode.getElementsByTagName('requirement-details');
        if reqDetailsList.getLength == 0
            error('<requirement-details> not found inside header.');
        end

        reqDetailsNode = reqDetailsList.item(0);
        reqList = reqDetailsNode.getElementsByTagName('requirement');
        n = reqList.getLength;
        if n == 0
            warning('No requirements found inside <requirement-details>.');
            return;
        end
        
        req_table = cell(n, 3);
        for i = 0:n-1
            node = reqList.item(i);
            req_id = char(node.getAttribute('id'));
            if node.hasAttribute('doors-link')
                link = char(node.getAttribute('doors-link'));
            else
                link = '';
            end
            
            if node.hasAttribute('text')
                description = char(node.getAttribute('text'));
            else
                description = '';
            end

            req_table{i+1,1} = req_id;
            req_table{i+1,2} = link;
            req_table{i+1,3} = description;
        end

        [folder, name, ~] = fileparts(xmlPath);
        dataFolder = dir(fullfile(folder, '*_data'));
        dataFolderPath = [dataFolder.folder, '\', dataFolder.name];
        matFile = fullfile(dataFolderPath, [name '_requirements.mat']);
        save(matFile, 'req_table');
        fprintf('Requirements (header only) saved to: %s\n', matFile);
    catch ME
        fprintf('ERROR: %s\n', ME.message);
    end
end