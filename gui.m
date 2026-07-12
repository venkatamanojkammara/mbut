function gui()

clc;

%% ===== MODERN DESKTOP THEME =====
theme.fontName       = 'Segoe UI';
theme.fontSize       = 10;
theme.labelSize      = 10;
theme.buttonSize     = 10;
theme.canvas         = [0.945 0.953 0.965];
theme.surface        = [1.000 1.000 1.000];
theme.sidebar        = [0.105 0.125 0.160];
theme.sidebarText    = [0.900 0.920 0.950];
theme.primary        = [0.125 0.350 0.620];
theme.primaryHover   = [0.105 0.305 0.555];
theme.fontColor      = [0.105 0.125 0.160];
theme.muted          = [0.420 0.455 0.510];
theme.border         = [0.855 0.875 0.905];
theme.input          = [0.975 0.980 0.988];
theme.secondary      = [0.900 0.920 0.945];
theme.darkButton     = [0.120 0.145 0.185];
theme.success        = [0.145 0.520 0.330];
theme.warning        = [0.850 0.560 0.120];
theme.danger         = [0.925 0.935 0.948];

screenSize = get(0,'ScreenSize');
windowWidth  = min(1280,screenSize(3)-40);
windowHeight = min(760,screenSize(4)-80);
windowWidth  = max(windowWidth,900);
windowHeight = max(windowHeight,550);
windowX = max(round((screenSize(3)-windowWidth)/2),1);
windowY = max(round((screenSize(4)-windowHeight)/2),1);

fig = figure(...
    'Name','Model Based Testing Tool',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'ToolBar','none',...
    'Resize','on',...
    'Color',theme.canvas,...
    'Units','pixels',...
    'Position',[windowX windowY windowWidth windowHeight]);

setappdata(fig,'theme',theme);

%% ===== APP STATE =====
setappdata(fig,'mainModelPath','');
setappdata(fig,'submodulePath','');
setappdata(fig,'savePath','');

%% ===== APPLICATION SHELL =====
left = uipanel(fig,...
    'Units','normalized',...
    'Position',[0 0 0.195 1],...
    'BackgroundColor',theme.sidebar,...
    'BorderType','none');

header = uipanel(fig,...
    'Units','normalized',...
    'Position',[0.195 0.905 0.805 0.095],...
    'BackgroundColor',theme.surface,...
    'BorderType','none');

right = uipanel(fig,...
    'Units','normalized',...
    'Position',[0.195 0.040 0.805 0.865],...
    'BackgroundColor',theme.canvas,...
    'BorderType','none');

statusPanel = uipanel(fig,...
    'Units','normalized',...
    'Position',[0.195 0 0.805 0.040],...
    'BackgroundColor',theme.surface,...
    'BorderType','line',...
    'HighlightColor',theme.border,...
    'ShadowColor',theme.border);

setappdata(fig,'rightPanel',right);

%% ===== BRAND =====
uicontrol(left,'Style','text',...
    'Units','normalized',...
    'Position',[0.095 0.925 0.82 0.040],...
    'String','MBUT',...
    'HorizontalAlignment','left',...
    'BackgroundColor',theme.sidebar,...
    'ForegroundColor',[1 1 1],...
    'FontName',theme.fontName,...
    'FontSize',15,...
    'FontWeight','bold');

uicontrol(left,'Style','text',...
    'Units','normalized',...
    'Position',[0.095 0.892 0.82 0.030],...
    'String','SWE4 Unit Testing',...
    'HorizontalAlignment','left',...
    'BackgroundColor',theme.sidebar,...
    'ForegroundColor',[0.570 0.620 0.700],...
    'FontName',theme.fontName,...
    'FontSize',9);

%% ===== MODERN TAB NAVIGATION =====
navNames = {...
    'Model Setup',...
    'Test Case Management',...
    'Test Case Generation',...
    'Plot and Report',...
    'Batch Run'};

navY = [0.735 0.665 0.595 0.525 0.455];
navAxes = zeros(1,numel(navNames));
navRects = zeros(1,numel(navNames));
navTexts = zeros(1,numel(navNames));

for i = 1:numel(navNames)

    navAxes(i) = axes(...
        'Parent',left,...
        'Units','normalized',...
        'Position',[0.055 navY(i) 0.89 0.058],...
        'XLim',[0 1],...
        'YLim',[0 1],...
        'Visible','off',...
        'Color','none');

    navRects(i) = rectangle(...
        'Parent',navAxes(i),...
        'Position',[0.01 0.04 0.98 0.92],...
        'Curvature',[0.10 0.10],...
        'FaceColor',theme.sidebar,...
        'EdgeColor',theme.sidebar,...
        'LineWidth',1,...
        'ButtonDownFcn',@(s,e)switchModernTab(fig,i));

    navTexts(i) = text(...
        0.09,0.50,navNames{i},...
        'Parent',navAxes(i),...
        'HorizontalAlignment','left',...
        'VerticalAlignment','middle',...
        'FontName',theme.fontName,...
        'FontSize',10,...
        'FontWeight','normal',...
        'Color',theme.sidebarText,...
        'Interpreter','none',...
        'ButtonDownFcn',@(s,e)switchModernTab(fig,i));
end

setappdata(fig,'navNames',navNames);
setappdata(fig,'navRects',navRects);
setappdata(fig,'navTexts',navTexts);
setappdata(fig,'activeNavIndex',1);

uicontrol(left,'Style','text',...
    'Units','normalized',...
    'Position',[0.095 0.035 0.82 0.055],...
    'String',sprintf('MATLAB R2016b\nDesktop Application'),...
    'HorizontalAlignment','left',...
    'BackgroundColor',theme.sidebar,...
    'ForegroundColor',[0.480 0.530 0.610],...
    'FontName',theme.fontName,...
    'FontSize',8);

%% ===== HEADER =====
headerTitle = uicontrol(header,'Style','text',...
    'Units','normalized',...
    'Position',[0.035 0.47 0.70 0.38],...
    'String','Model Setup',...
    'HorizontalAlignment','left',...
    'BackgroundColor',theme.surface,...
    'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,...
    'FontSize',17,...
    'FontWeight','bold');

headerSubtitle = uicontrol(header,'Style','text',...
    'Units','normalized',...
    'Position',[0.036 0.13 0.80 0.28],...
    'String','Configure and prepare the model workspace',...
    'HorizontalAlignment','left',...
    'BackgroundColor',theme.surface,...
    'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,...
    'FontSize',9);

setappdata(fig,'headerTitle',headerTitle);
setappdata(fig,'headerSubtitle',headerSubtitle);

%% ===== STATUS BAR =====
statusIndicator = uicontrol(statusPanel,...
    'Style','text',...
    'Units','normalized',...
    'Position',[0.012 0.08 0.025 0.75],...
    'String',char(9679),...
    'HorizontalAlignment','center',...
    'BackgroundColor',theme.surface,...
    'ForegroundColor',theme.success,...
    'FontName','Segoe UI Symbol',...
    'FontSize',9);

status = uicontrol(statusPanel,...
    'Style','text',...
    'Units','normalized',...
    'Position',[0.040 0.08 0.70 0.75],...
    'String','Ready',...
    'HorizontalAlignment','left',...
    'BackgroundColor',theme.surface,...
    'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,...
    'FontSize',8.5);

uicontrol(statusPanel,'Style','text',...
    'Units','normalized',...
    'Position',[0.80 0.08 0.18 0.75],...
    'String','MBUT',...
    'HorizontalAlignment','right',...
    'BackgroundColor',theme.surface,...
    'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,...
    'FontSize',8);

setappdata(fig,'statusText',status);
setappdata(fig,'statusIndicator',statusIndicator);

%% DEFAULT
switchModernTab(fig,1);

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

function switchModernTab(fig,index)

theme = getappdata(fig,'theme');
right = getappdata(fig,'rightPanel');
navNames = getappdata(fig,'navNames');
navRects = getappdata(fig,'navRects');
navTexts = getappdata(fig,'navTexts');

if isempty(index) || index < 1 || index > numel(navNames)
    return;
end

for i = 1:numel(navNames)
    if ishandle(navRects(i))
        if i == index
            set(navRects(i),...
                'FaceColor',theme.primary,...
                'EdgeColor',theme.primary);
            set(navTexts(i),...
                'Color',[1 1 1],...
                'FontWeight','bold');
        else
            set(navRects(i),...
                'FaceColor',theme.sidebar,...
                'EdgeColor',theme.sidebar);
            set(navTexts(i),...
                'Color',theme.sidebarText,...
                'FontWeight','normal');
        end
    end
end

setappdata(fig,'activeNavIndex',index);

setStatus(fig,['Opening ' navNames{index} '...']);
drawnow;

delete(allchild(right));

switch navNames{index}
    case 'Model Setup'
        view_ModelSetup(fig);

    case 'Test Case Management'
        view_TestCaseManagement(fig);

    case 'Test Case Generation'
        setHeader(fig,'Test Case Generation','Generate test cases using the configured workflow');
        setStatus(fig,'Running Test Case Generation...');
        drawnow;
        runPythonExe();
        setStatus(fig,'Ready');

    case 'Plot and Report'
        view_PlotAndReport(fig);

    case 'Batch Run'
        view_BatchRun(fig);
end

drawnow;

end

function switchView(fig,evt)

right = getappdata(fig,'rightPanel');

node = evt.getCurrentNode;
name = char(node.getName);

delete(allchild(right));

setStatus(fig,['Viewing: ' name]);

switch name
    case 'Model Setup'
        view_ModelSetup(fig);

    case 'Test Case Management'
        view_TestCaseManagement(fig);

    case 'Simulation'
        view_Simulation(fig);

    case 'Plot and Report'
        view_PlotAndReport(fig);

    case 'Batch Run'
        view_BatchRun(fig);

    case 'Test Case Generation'
        setStatus(fig,'Running Test Case Generation...');
        drawnow;
        runPythonExe();
        setStatus(fig,'Ready');
end

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

function view_ModelSetup(fig)

p = getappdata(fig,'rightPanel');
theme = getappdata(fig,'theme');

card1 = createCard(p,[0.040 0.405 0.920 0.550]);
card2 = createCard(p,[0.040 0.085 0.920 0.280]);

bg1 = get(card1,'BackgroundColor');
bg2 = get(card2,'BackgroundColor');

%% MODEL CONFIGURATION HEADER
uicontrol(card1,'Style','text','String','Model Configuration',...
    'Units','normalized','Position',[0.045 0.865 0.50 0.070],...
    'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',14,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(card1,'Style','text',...
    'String','Configure the Simulink model, target submodule and workspace location.',...
    'Units','normalized','Position',[0.045 0.795 0.75 0.050],...
    'BackgroundColor',bg1,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(card1,[0.045 0.755 0.910 0.003],theme);

%% MODEL FIELDS
labels = {'Main Model','Submodule','Save Path'};
descriptions = {...
    'Select Main Simulink model file',...
    'Select System Under Test',...
    'Select output workspace directory'};
ys = [0.590 0.395 0.200];

for i = 1:3
    uicontrol(card1,'Style','text','String',labels{i},...
        'Units','normalized','Position',[0.045 ys(i)+0.035 0.160 0.065],...
        'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
        'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
        'HorizontalAlignment','left');

    uicontrol(card1,'Style','text','String',descriptions{i},...
        'Units','normalized','Position',[0.045 ys(i)-0.025 0.160 0.060],...
        'BackgroundColor',bg1,'ForegroundColor',theme.muted,...
        'FontName',theme.fontName,'FontSize',8,...
        'HorizontalAlignment','left');
end

mainBox = createModernEdit(card1,[0.220 0.590 0.565 0.110],theme,'');
subBox  = createModernEdit(card1,[0.220 0.395 0.565 0.110],theme,'');
saveBox = createModernEdit(card1,[0.220 0.200 0.565 0.110],theme,'');

set(mainBox,'String',getappdata(fig,'mainModelPath'));
set(subBox,'String',getappdata(fig,'submodulePath'));
set(saveBox,'String',getappdata(fig,'savePath'));

set(mainBox,'Callback',@(s,e)setappdata(fig,'mainModelPath',get(s,'String')));
set(subBox,'Callback',@(s,e)setappdata(fig,'submodulePath',get(s,'String')));
set(saveBox,'Callback',@(s,e)setappdata(fig,'savePath',get(s,'String')));

createModernButton(card1,[0.815 0.590 0.140 0.110],...
    'Browse',theme,'secondary',@(s,e)browseModelFile(mainBox));

createModernButton(card1,[0.815 0.395 0.140 0.110],...
    'Browse',theme,'secondary',@(s,e)showSubmoduleTree(mainBox,subBox,fig));

createModernButton(card1,[0.815 0.200 0.140 0.110],...
    'Browse',theme,'secondary',@(s,e)browseSavePath(saveBox));

createModernButton(card1,[0.390 0.045 0.220 0.105],...
    'Save Information',theme,'primary',@(s,e)saveInfo(mainBox,subBox,saveBox));

%% TEST FRAME CARD
uicontrol(card2,'Style','text','String','Test Frame',...
    'Units','normalized','Position',[0.045 0.745 0.50 0.110],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',13,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(card2,'Style','text',...
    'String','Create a new test frame or continue from an existing model.',...
    'Units','normalized','Position',[0.045 0.620 0.75 0.090],...
    'BackgroundColor',bg2,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(card2,[0.045 0.565 0.910 0.005],theme);

createModernButton(card2,[0.045 0.135 0.435 0.300],...
    'Generate Test Frame',theme,'primary',...
    @(s,e)runFrameCreation(mainBox,subBox,[],[],saveBox));

createModernButton(card2,[0.520 0.135 0.435 0.300],...
    'Open Existing Test Frame',theme,'dark',...
    @(s,e)openSLXFile());

setappdata(fig,'mainModelPathBox',mainBox);
setappdata(fig,'submoduleBox',subBox);
setappdata(fig,'savePathBox',saveBox);

setHeader(fig,'Model Setup','Configure and prepare the model workspace');
setStatus(fig,'Ready');
applyModernUI(fig);

end

function view_TestCaseManagement(fig)

p = getappdata(fig,'rightPanel');
theme = getappdata(fig,'theme');

sourceCard = createCard(p,[0.040 0.625 0.920 0.330]);
configCard = createCard(p,[0.040 0.055 0.920 0.535]);

bg1 = get(sourceCard,'BackgroundColor');
bg2 = get(configCard,'BackgroundColor');

%% SOURCE CARD
uicontrol(sourceCard,'Style','text','String','Test Case Source',...
    'Units','normalized','Position',[0.040 0.845 0.45 0.085],...
    'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',13,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(sourceCard,'Style','text',...
    'String','Load the test definition and configure the simulation sample time.',...
    'Units','normalized','Position',[0.040 0.745 0.75 0.065],...
    'BackgroundColor',bg1,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(sourceCard,[0.040 0.690 0.920 0.004],theme);

uicontrol(sourceCard,'Style','text','String','Test Case File',...
    'Units','normalized','Position',[0.040 0.445 0.155 0.100],...
    'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','left');

xlsBox = createModernEdit(sourceCard,[0.205 0.430 0.455 0.140],theme,'');

createModernButton(sourceCard,[0.680 0.430 0.115 0.140],...
    'Browse',theme,'secondary',@(s,e)browseXLS(xlsBox));

createModernButton(sourceCard,[0.815 0.430 0.145 0.140],...
    'Load Test Cases',theme,'primary',...
    @(s,e)loadTestCases(xlsBox,getappdata(fig,'testSeqList'),...
    getappdata(fig,'savePathBox'),1));

uicontrol(sourceCard,'Style','text','String','Sample Time',...
    'Units','normalized','Position',[0.040 0.155 0.155 0.100],...
    'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','left');

stepTimeBox = createModernEdit(sourceCard,[0.205 0.140 0.160 0.140],theme,'0.01');

uicontrol(sourceCard,'Style','text','String','Simulation step size',...
    'Units','normalized','Position',[0.385 0.155 0.230 0.090],...
    'BackgroundColor',bg1,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',8.5,...
    'HorizontalAlignment','left');

createModernButton(sourceCard,[0.815 0.140 0.145 0.140],...
    'Load Parameters',theme,'secondary',@(s,e)loadTxtParameters(fig));

%% EXECUTION CONFIGURATION
uicontrol(configCard,'Style','text','String','Execution Configuration',...
    'Units','normalized','Position',[0.040 0.895 0.48 0.060],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',13,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(configCard,'Style','text',...
    'String','Select test cases and configure the required verification mode.',...
    'Units','normalized','Position',[0.040 0.825 0.70 0.050],...
    'BackgroundColor',bg2,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(configCard,[0.040 0.795 0.920 0.003],theme);
createDivider(configCard,[0.650 0.075 0.002 0.670],theme);

uicontrol(configCard,'Style','text','String','Available Test Cases',...
    'Units','normalized','Position',[0.040 0.710 0.270 0.055],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(configCard,'Style','text','String','Selected Test Cases',...
    'Units','normalized','Position',[0.355 0.710 0.270 0.055],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','left');

listBox = createModernList(configCard,[0.040 0.220 0.270 0.465],theme);
set(listBox,'Min',1,'Max',10,...
    'Callback',@(s,e)onTestSeqDoubleClick(fig,s));

selectedList = createModernList(configCard,[0.355 0.220 0.270 0.465],theme);
set(selectedList,'Min',0,'Max',10);

createModernButton(configCard,[0.040 0.075 0.270 0.110],...
    'Select All',theme,'primary',@(s,e)selectAllSeqs(fig));

createModernButton(configCard,[0.355 0.075 0.270 0.110],...
    'Delete Selected',theme,'danger',@(s,e)deleteSelectedTS(fig));

milChk = createModernCheck(configCard,[0.690 0.610 0.105 0.070],'MIL',theme);
silChk = createModernCheck(configCard,[0.815 0.610 0.105 0.070],'SIL',theme);

code_coverage_type = createModernPopup(configCard,[0.690 0.400 0.265 0.085],...
    {'No Coverage','Statement Coverage (C0)','Decision Coverage (C1)'},theme);

execSimBtn = createModernButton(configCard,[0.690 0.220 0.265 0.130],...
    'Execute Simulation',theme,'primary',...
    @(s,e)executeSimulation(getappdata(fig,'mtcdXlsBox'),...
    getappdata(fig,'savePathBox')));

genCodeBtn = createModernButton(configCard,[0.690 0.075 0.265 0.110],...
    'Generate Code',theme,'dark',@(s,e)generateCodeCallback(fig));

xlsPath = getappdata(fig,'mtcdXlsPath');
if ~isempty(xlsPath), set(xlsBox,'String',xlsPath); end

storedList = getappdata(fig,'testSeqListStored');
if ~isempty(storedList), set(listBox,'String',storedList); end

stepTimeVal = getappdata(fig,'stepTimeBox');
if ~isempty(stepTimeVal) && ischar(stepTimeVal)
    set(stepTimeBox,'String',stepTimeVal);
end

milVal = getappdata(fig,'milChk');
% if ~isempty(milVal)
%     set(milChk,'Value',milVal);
% end

silVal = getappdata(fig,'silChk');
% if ~isempty(silVal)
%     set(silChk,'Value',silVal);
% end

setappdata(fig,'mtcdXlsBox',xlsBox);
setappdata(fig,'testSeqList',listBox);
setappdata(fig,'selectedTestSeqList',selectedList);
setappdata(fig,'code_coverage_type',code_coverage_type);
setappdata(fig,'stepTimeBox',stepTimeBox);
setappdata(fig,'milChk',milChk);
setappdata(fig,'silChk',silChk);
setappdata(fig,'execSimBtn',execSimBtn);
setappdata(fig,'genCodeBtn',genCodeBtn);

pushWS(fig,'stepTimeBox',stepTimeBox);

setHeader(fig,'Test Case Management','Load, select and configure test cases for execution');
setStatus(fig,'Ready');
applyModernUI(fig);

end

function view_PlotAndReport(fig)

p = getappdata(fig,'rightPanel');
theme = getappdata(fig,'theme');

set(fig,'ResizeFcn',@resizeUI);

plotCard = createCard(p,[0.040 0.555 0.920 0.400]);
reportCard = createCard(p,[0.040 0.060 0.920 0.455]);

bg1 = get(plotCard,'BackgroundColor');
bg2 = get(reportCard,'BackgroundColor');

%% SIGNAL PLOTTING
uicontrol(plotCard,'Style','text','String','Signal Plotting',...
    'Units','normalized','Position',[0.045 0.845 0.45 0.085],...
    'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',13,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(plotCard,'Style','text',...
    'String','Select the test sequence, signal and comparison mode for analysis.',...
    'Units','normalized','Position',[0.045 0.745 0.75 0.065],...
    'BackgroundColor',bg1,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(plotCard,[0.045 0.700 0.910 0.004],theme);

labels = {'TS Folder','Signal','Compare'};
xs = [0.045 0.355 0.665];

for i = 1:3
    uicontrol(plotCard,'Style','text','String',labels{i},...
        'Units','normalized','Position',[xs(i) 0.555 0.25 0.070],...
        'BackgroundColor',bg1,'ForegroundColor',theme.fontColor,...
        'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
        'HorizontalAlignment','left');
end

ddFolders = createModernPopup(plotCard,[0.045 0.390 0.260 0.110],...
    {'<TS Folder>'},theme);

ddSignals = createModernPopup(plotCard,[0.355 0.390 0.260 0.110],...
    {'<Signal>'},theme);

ddCompare = createModernPopup(plotCard,[0.665 0.390 0.290 0.110],...
    {'MIL vs Expected','MIL vs SIL'},theme);

createModernButton(plotCard,[0.370 0.115 0.260 0.160],...
    'Plot Signal',theme,'primary',...
    @(s,e)onPlotSignal(ddFolders,ddSignals,ddCompare));

setappdata(fig,'sim_ddFolders',ddFolders);
setappdata(fig,'sim_ddSignals',ddSignals);
setappdata(fig,'sim_ddCompare',ddCompare);

%% REPORT GENERATION
uicontrol(reportCard,'Style','text','String','Report Generation',...
    'Units','normalized','Position',[0.045 0.845 0.45 0.085],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',13,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(reportCard,'Style','text',...
    'String','Configure coverage targets and generate the consolidated verification report.',...
    'Units','normalized','Position',[0.045 0.755 0.80 0.060],...
    'BackgroundColor',bg2,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(reportCard,[0.045 0.710 0.910 0.004],theme);
createDivider(reportCard,[0.565 0.160 0.002 0.430],theme);

uicontrol(reportCard,'Style','text','String','Target Coverage',...
    'Units','normalized','Position',[0.070 0.505 0.190 0.090],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','left');

targetBox = createModernEdit(reportCard,[0.275 0.500 0.230 0.105],theme,'80');

uicontrol(reportCard,'Style','text','String','Coverage Type',...
    'Units','normalized','Position',[0.070 0.290 0.190 0.090],...
    'BackgroundColor',bg2,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','left');

covTypeDropdown = createModernPopup(reportCard,[0.275 0.285 0.230 0.105],...
    {'No Coverage','Statement Coverage (C0)','Decision Coverage (C1)'},theme);

btn = createModernButton(reportCard,[0.635 0.250 0.280 0.250],...
    'Generate Report',theme,'dark',...
    @(s,e)generateHTMLReport(getappdata(fig,'mtcdXlsPath')));

setappdata(fig,'targetCoverageBox',targetBox);
setappdata(fig,'coverageTypeDropdown',covTypeDropdown);
setappdata(fig,'reportBtn',btn);

populateTsFolders(fig);
onSignalChanged(fig);

setHeader(fig,'Plot and Report','Analyse simulation signals and generate verification reports');
setStatus(fig,'Ready');
applyModernUI(fig);

end

function resizeUI(src,~)

fig = src;

targetBox = getappdata(fig,'targetCoverageBox');
covDD = getappdata(fig,'coverageTypeDropdown');
btn = getappdata(fig,'reportBtn');

if isempty(targetBox) || ~isvalid(targetBox)
    return;
end

figPos = get(fig,'Position');
figH = figPos(4);

% ? Vertical scaling factor
scaleH = max(0.08, min(0.14, figH / 900));
fontSize = max(10, min(16, round(figH / 70)));

% ? Update control heights
pos = get(targetBox,'Position');
pos(4) = scaleH;
set(targetBox,'Position',pos,'FontSize',fontSize);

pos = get(covDD,'Position');
pos(4) = scaleH;
set(covDD,'Position',pos,'FontSize',fontSize);

% ? Button grows vertically
pos = get(btn,'Position');
pos(4) = scaleH + 0.05;
set(btn,'Position',pos,'FontSize',fontSize);

end

function view_BatchRun(fig)

p = getappdata(fig,'rightPanel');
theme = getappdata(fig,'theme');

card = createCard(p,[0.040 0.060 0.920 0.895]);
bg = get(card,'BackgroundColor');

uicontrol(card,'Style','text','String','Batch Run',...
    'Units','normalized','Position',[0.045 0.900 0.45 0.065],...
    'BackgroundColor',bg,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',14,'FontWeight','bold',...
    'HorizontalAlignment','left');

uicontrol(card,'Style','text',...
    'String','Manage multiple XML test case files and execute automated batch workflows.',...
    'Units','normalized','Position',[0.045 0.840 0.75 0.050],...
    'BackgroundColor',bg,'ForegroundColor',theme.muted,...
    'FontName',theme.fontName,'FontSize',9.5,...
    'HorizontalAlignment','left');

createDivider(card,[0.045 0.810 0.910 0.003],theme);

uicontrol(card,'Style','text','String','Test Case Files',...
    'Units','normalized','Position',[0.045 0.735 0.35 0.055],...
    'BackgroundColor',bg,'ForegroundColor',theme.fontColor,...
    'FontName',theme.fontName,'FontSize',11,'FontWeight','bold',...
    'HorizontalAlignment','left');

excelListBox = createModernList(card,[0.045 0.250 0.910 0.415],theme);
set(excelListBox,'Min',1,'Max',10,...
    'Callback',@(s,e)onExcelPathSelected(fig,s));

setappdata(fig,'excelPathListBox',excelListBox);

createDivider(card,[0.045 0.215 0.910 0.003],theme);

createModernButton(card,[0.045 0.085 0.165 0.085],...
    'Add XML',theme,'primary',@(s,e)addExcelCallback(fig));

delBtn = createModernButton(card,[0.230 0.085 0.145 0.085],...
    'Delete',theme,'danger',@(s,e)deleteSelectedExcel(fig));
set(delBtn,'Enable','off');

createDivider(card,[0.410 0.085 0.002 0.085],theme);

createModernButton(card,[0.450 0.085 0.190 0.085],...
    'Execute Simulation',theme,'primary',@(s,e)onExecuteSimulation(fig));

createModernButton(card,[0.660 0.085 0.130 0.085],...
    'Batch Run',theme,'dark',@(s,e)onAutomaticBatchRun(fig));

createModernButton(card,[0.810 0.085 0.145 0.085],...
    'Test Cases Run',theme,'dark',@(s,e)onRunTestCases(fig));

setappdata(fig,'deleteExcelBtn',delBtn);

if ~isappdata(fig,'excelPathList')
    setappdata(fig,'excelPathList',{});
end

setappdata(fig,'selectedExcelIdx',[]);

paths = getappdata(fig,'excelPathList');

if ~isempty(paths)
    set(excelListBox,'String',paths);
else
    set(excelListBox,'String',{});
end

setHeader(fig,'Batch Run','Manage test case files and execute automated batch workflows');
setStatus(fig,'Ready');
applyModernUI(fig);

end

function applyModernUI(fig)

    if isempty(fig) || ~ishandle(fig)
        return;
    end

    theme = getappdata(fig,'theme');
    if isempty(theme) || ~isstruct(theme)
        return;
    end

    allText = findall(fig,'Style','text');
    for k = 1:numel(allText)
        try
            set(allText(k),'FontName',theme.fontName);
        catch
        end
    end

    allEdit = findall(fig,'Style','edit');
    for k = 1:numel(allEdit)
        try
            set(allEdit(k),...
                'FontName',theme.fontName,...
                'BackgroundColor',theme.input,...
                'ForegroundColor',theme.fontColor);
            applyRoundedJavaBorder(allEdit(k),theme.border,7);
        catch
        end
    end

    allList = findall(fig,'Style','listbox');
    for k = 1:numel(allList)
        try
            set(allList(k),...
                'FontName',theme.fontName,...
                'BackgroundColor',theme.input,...
                'ForegroundColor',theme.fontColor);
            applyRoundedJavaBorder(allList(k),theme.border,7);
        catch
        end
    end

    allPopup = findall(fig,'Style','popupmenu');
    for k = 1:numel(allPopup)
        try
            set(allPopup(k),...
                'FontName',theme.fontName,...
                'BackgroundColor',theme.input,...
                'ForegroundColor',theme.fontColor);
            applyRoundedJavaBorder(allPopup(k),theme.border,7);
        catch
        end
    end

    % Rounded buttons are custom axes + rectangle controls.
    logicalButtons = findall(fig,'Style','pushbutton');
    for k = 1:numel(logicalButtons)
        try
            if isappdata(logicalButtons(k),'RoundedButtonRect')
                syncRoundedButtonState(logicalButtons(k));
            end
        catch
        end
    end

    drawnow;

end

function applyRoundedButtonBorder(hButton,isPrimary,isDark,theme)

    try
        if exist('findjobj','file') ~= 2
            return;
        end

        jButton = findjobj(hButton);

        if isempty(jButton)
            return;
        end

        if iscell(jButton)
            jButton = jButton{1};
        end

        if isPrimary
            rgb = theme.primary;
        elseif isDark
            rgb = theme.darkButton;
        else
            rgb = theme.border;
        end

        jColor = java.awt.Color(single(rgb(1)),single(rgb(2)),single(rgb(3)));

        roundedBorder = javax.swing.border.CompoundBorder(...
            javax.swing.border.LineBorder(jColor,1,true),...
            javax.swing.border.EmptyBorder(4,10,4,10));

        jButton.setBorder(roundedBorder);
        jButton.setFocusPainted(false);
        jButton.setOpaque(true);
        jButton.setContentAreaFilled(true);
        jButton.setRolloverEnabled(true);

    catch
    end

end

function setHeader(fig,titleText,subtitleText)

    try
        hTitle = getappdata(fig,'headerTitle');
        hSubtitle = getappdata(fig,'headerSubtitle');

        if ~isempty(hTitle) && ishandle(hTitle)
            set(hTitle,'String',titleText);
        end

        if ~isempty(hSubtitle) && ishandle(hSubtitle)
            set(hSubtitle,'String',subtitleText);
        end
    catch
    end

end

function attachButtonFeedback(hButton,fig)

    try
        if isappdata(hButton,'ModernFeedbackAttached')
            return;
        end

        originalCallback = get(hButton,'Callback');

        if isempty(originalCallback)
            return;
        end

        setappdata(hButton,'OriginalModernCallback',originalCallback);
        setappdata(hButton,'ModernFeedbackAttached',true);

        set(hButton,'Callback',@(s,e)modernButtonAction(s,e,fig));

    catch
    end

end

function modernButtonAction(source,eventData,fig)

    originalCallback = getappdata(source,'OriginalModernCallback');

    oldBackground = getappdata(source,'ModernButtonBackground');
    oldForeground = getappdata(source,'ModernButtonForeground');
    oldString = get(source,'String');

    if isempty(oldBackground)
        oldBackground = get(source,'BackgroundColor');
    end

    if isempty(oldForeground)
        oldForeground = get(source,'ForegroundColor');
    end

    try
        % Quiet pressed feedback: slightly darker surface only.
        pressedColor = max(oldBackground .* 0.92,0);

        set(source,...
            'BackgroundColor',pressedColor,...
            'ForegroundColor',oldForeground);

        setStatus(fig,[oldString '...']);
        drawnow;
        pause(0.045);

        set(source,...
            'BackgroundColor',oldBackground,...
            'ForegroundColor',oldForeground);
        drawnow;

        if isa(originalCallback,'function_handle')
            originalCallback(source,eventData);
        elseif iscell(originalCallback)
            feval(originalCallback{1},source,eventData,originalCallback{2:end});
        elseif ischar(originalCallback)
            eval(originalCallback);
        end

        if ishandle(source)
            set(source,...
                'BackgroundColor',oldBackground,...
                'ForegroundColor',oldForeground,...
                'String',oldString);
        end

        drawnow;

    catch ME

        if ishandle(source)
            set(source,...
                'BackgroundColor',oldBackground,...
                'ForegroundColor',oldForeground,...
                'String',oldString);
        end

        setStatus(fig,['Action failed: ' ME.message]);
        drawnow;
        rethrow(ME);
    end

end

function applyRoundedJavaBorder(hControl,rgb,padding)

    try
        if exist('findjobj','file') ~= 2
            return;
        end

        jControl = findjobj(hControl);

        if isempty(jControl)
            return;
        end

        if iscell(jControl)
            jControl = jControl{1};
        end

        jColor = java.awt.Color(single(rgb(1)),single(rgb(2)),single(rgb(3)));

        border = javax.swing.border.CompoundBorder(...
            javax.swing.border.LineBorder(jColor,1,true),...
            javax.swing.border.EmptyBorder(2,padding,2,padding));

        jControl.setBorder(border);

    catch
    end

end

function setStatus(fig,msg)
h = getappdata(fig,'statusText');
if ishandle(h)
    set(h,'String',['  ' msg]);
end
drawnow;
end

function h = createModernButton(parent,pos,label,theme,buttonType,callbackFcn)

    % =========================================================
    % REAL ROUNDED BUTTON FOR MATLAB R2016b
    %
    % Native pushbuttons cannot render rounded corners.
    % A hidden pushbutton is retained as the logical handle so
    % existing set(...,'Enable',...) and appdata logic continue
    % to work. The visible button is drawn using an axes and a
    % rounded rectangle.
    % =========================================================

    switch lower(buttonType)
        case 'primary'
            bg = [0.205 0.330 0.465];
            fg = [1.000 1.000 1.000];
            borderColor = [0.205 0.330 0.465];

        case 'dark'
            bg = [0.205 0.225 0.255];
            fg = [0.965 0.972 0.980];
            borderColor = [0.205 0.225 0.255];

        otherwise
            % Includes previous "danger" buttons intentionally.
            % Keep the interface restrained and professional.
            bg = [0.940 0.948 0.958];
            fg = [0.250 0.280 0.315];
            borderColor = [0.790 0.815 0.845];
    end

    % Logical proxy handle. Existing backend/UI code can still use:
    % set(h,'Enable','on/off')
    h = uicontrol(parent,...
        'Style','pushbutton',...
        'Units','normalized',...
        'Position',pos,...
        'String',label,...
        'Visible','off',...
        'Callback',callbackFcn);

    % Visible rounded button layer.
    ax = axes(...
        'Parent',parent,...
        'Units','normalized',...
        'Position',pos,...
        'XLim',[0 1],...
        'YLim',[0 1],...
        'Visible','off',...
        'Color','none',...
        'HitTest','on');

    roundedRect = rectangle(...
        'Parent',ax,...
        'Position',[0.015 0.08 0.970 0.84],...
        'Curvature',[0.05 0.05],...
        'FaceColor',bg,...
        'EdgeColor',borderColor,...
        'LineWidth',1.0,...
        'HitTest','on');

    buttonText = text(...
        0.50,0.50,label,...
        'Parent',ax,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','middle',...
        'FontName',theme.fontName,...
        'FontSize',9.5,...
        'FontWeight','bold',...
        'Color',fg,...
        'Interpreter','none',...
        'HitTest','on');

    set(ax,'ButtonDownFcn',@(s,e)modernRoundedButtonAction(h,e));
    set(roundedRect,'ButtonDownFcn',@(s,e)modernRoundedButtonAction(h,e));
    set(buttonText,'ButtonDownFcn',@(s,e)modernRoundedButtonAction(h,e));

    setappdata(h,'ModernButtonType',buttonType);
    setappdata(h,'ModernButtonBackground',bg);
    setappdata(h,'ModernButtonForeground',fg);
    setappdata(h,'ModernButtonBorderColor',borderColor);
    setappdata(h,'RoundedButtonAxes',ax);
    setappdata(h,'RoundedButtonRect',roundedRect);
    setappdata(h,'RoundedButtonText',buttonText);
    setappdata(h,'OriginalModernCallback',callbackFcn);

    % Synchronise Enable changes made by the existing application.
    try
        enableListener = addlistener(h,'Enable','PostSet',...
            @(s,e)syncRoundedButtonState(h));
        setappdata(h,'RoundedButtonEnableListener',enableListener);
    catch
    end

    syncRoundedButtonState(h);

end

function styleModernButton(hButton,theme)

    if isempty(hButton) || ~ishandle(hButton)
        return;
    end

    try
        bg = getappdata(hButton,'ModernButtonBackground');
        fg = getappdata(hButton,'ModernButtonForeground');
        borderColor = getappdata(hButton,'ModernButtonBorderColor');

        if isempty(bg)
            bg = get(hButton,'BackgroundColor');
        end

        if isempty(fg)
            fg = get(hButton,'ForegroundColor');
        end

        if isempty(borderColor)
            borderColor = [0.805 0.830 0.860];
        end

        set(hButton,...
            'BackgroundColor',bg,...
            'ForegroundColor',fg,...
            'FontName',theme.fontName,...
            'FontSize',9.5,...
            'FontWeight','bold');

        if exist('findjobj','file') == 2

            jButton = findjobj(hButton);

            if iscell(jButton)
                jButton = jButton{1};
            end

            if ~isempty(jButton)

                jBorderColor = java.awt.Color(...
                    single(borderColor(1)),...
                    single(borderColor(2)),...
                    single(borderColor(3)));

                % Very subtle rounded corners. The border is intentionally
                % restrained to retain a professional desktop application feel.
                outerBorder = javax.swing.border.LineBorder(...
                    jBorderColor,1,true);

                innerBorder = javax.swing.border.EmptyBorder(...
                    4,12,4,12);

                jButton.setBorder(javax.swing.border.CompoundBorder(...
                    outerBorder,innerBorder));

                jButton.setFocusPainted(false);
                jButton.setOpaque(true);
                jButton.setContentAreaFilled(true);
                jButton.setRolloverEnabled(true);

                try
                    jButton.setCursor(java.awt.Cursor(...
                        java.awt.Cursor.HAND_CURSOR));
                catch
                end

            end
        end

        attachButtonFeedback(hButton,ancestor(hButton,'figure'));

    catch
    end

end

function applyButtonStyleToAll(fig)

    if isempty(fig) || ~ishandle(fig)
        return;
    end

    theme = getappdata(fig,'theme');
    buttons = findall(fig,'Style','pushbutton');

    for i = 1:numel(buttons)

        hButton = buttons(i);
        buttonType = getappdata(hButton,'ModernButtonType');

        if isempty(buttonType)

            currentBg = get(hButton,'BackgroundColor');

            if norm(currentBg-theme.primary) < 0.08
                buttonType = 'primary';
            elseif norm(currentBg-theme.darkButton) < 0.08
                buttonType = 'dark';
            elseif norm(currentBg-theme.danger) < 0.08
                buttonType = 'danger';
            else
                buttonType = 'secondary';
            end

            switch lower(buttonType)
                case 'primary'
                    bg = [0.180 0.315 0.475];
                    fg = [1 1 1];
                    borderColor = bg;

                case 'dark'
                    bg = [0.175 0.195 0.225];
                    fg = [0.970 0.975 0.985];
                    borderColor = bg;

                otherwise
                    bg = [0.945 0.953 0.965];
                    fg = [0.245 0.275 0.315];
                    borderColor = [0.805 0.830 0.860];
            end

            setappdata(hButton,'ModernButtonType',buttonType);
            setappdata(hButton,'ModernButtonBackground',bg);
            setappdata(hButton,'ModernButtonForeground',fg);
            setappdata(hButton,'ModernButtonBorderColor',borderColor);
        end

        styleModernButton(hButton,theme);
    end

    drawnow;

end

function modernRoundedButtonAction(hButton,eventData)

    if isempty(hButton) || ~ishandle(hButton)
        return;
    end

    if strcmpi(get(hButton,'Enable'),'off')
        return;
    end

    fig = ancestor(hButton,'figure');
    originalCallback = getappdata(hButton,'OriginalModernCallback');

    roundedRect = getappdata(hButton,'RoundedButtonRect');
    buttonText = getappdata(hButton,'RoundedButtonText');

    bg = getappdata(hButton,'ModernButtonBackground');
    fg = getappdata(hButton,'ModernButtonForeground');
    label = get(hButton,'String');

    try
        pressedColor = max(bg .* 0.88,0);

        if ishandle(roundedRect)
            set(roundedRect,'FaceColor',pressedColor);
        end

        if ishandle(buttonText)
            set(buttonText,'Position',[0.50 0.47 0]);
        end

        setStatus(fig,[label '...']);
        drawnow;
        pause(0.055);

        if ishandle(roundedRect)
            set(roundedRect,'FaceColor',bg);
        end

        if ishandle(buttonText)
            set(buttonText,'Position',[0.50 0.50 0]);
        end

        drawnow;

        if isa(originalCallback,'function_handle')
            originalCallback(hButton,eventData);
        elseif iscell(originalCallback)
            feval(originalCallback{1},hButton,eventData,originalCallback{2:end});
        elseif ischar(originalCallback)
            eval(originalCallback);
        end

        syncRoundedButtonState(hButton);

    catch ME

        if ishandle(roundedRect)
            set(roundedRect,'FaceColor',bg);
        end

        if ishandle(buttonText)
            set(buttonText,...
                'Position',[0.50 0.50 0],...
                'Color',fg);
        end

        setStatus(fig,['Action failed: ' ME.message]);
        drawnow;
        rethrow(ME);
    end

end

function syncRoundedButtonState(hButton)

    if isempty(hButton) || ~ishandle(hButton)
        return;
    end

    roundedRect = getappdata(hButton,'RoundedButtonRect');
    buttonText = getappdata(hButton,'RoundedButtonText');

    bg = getappdata(hButton,'ModernButtonBackground');
    fg = getappdata(hButton,'ModernButtonForeground');
    borderColor = getappdata(hButton,'ModernButtonBorderColor');

    if strcmpi(get(hButton,'Enable'),'off')
        displayBg = [0.925 0.932 0.942];
        displayFg = [0.600 0.625 0.655];
        displayBorder = [0.855 0.870 0.890];
    else
        displayBg = bg;
        displayFg = fg;
        displayBorder = borderColor;
    end

    if ~isempty(roundedRect) && ishandle(roundedRect)
        set(roundedRect,...
            'FaceColor',displayBg,...
            'EdgeColor',displayBorder);
    end

    if ~isempty(buttonText) && ishandle(buttonText)
        set(buttonText,...
            'String',get(hButton,'String'),...
            'Color',displayFg);
    end

    drawnow;

end

function h = createModernEdit(parent,pos,theme,value)

    h = uicontrol(parent,...
        'Style','edit',...
        'Units','normalized',...
        'Position',pos,...
        'String',value,...
        'HorizontalAlignment','left',...
        'FontName',theme.fontName,...
        'FontSize',10,...
        'ForegroundColor',theme.fontColor,...
        'BackgroundColor',theme.input);

end

function h = createModernPopup(parent,pos,items,theme)

    h = uicontrol(parent,...
        'Style','popupmenu',...
        'Units','normalized',...
        'Position',pos,...
        'String',items,...
        'Value',1,...
        'FontName',theme.fontName,...
        'FontSize',10,...
        'ForegroundColor',theme.fontColor,...
        'BackgroundColor',theme.input);

end

function h = createModernList(parent,pos,theme)

    h = uicontrol(parent,...
        'Style','listbox',...
        'Units','normalized',...
        'Position',pos,...
        'BackgroundColor',theme.input,...
        'ForegroundColor',theme.fontColor,...
        'FontName',theme.fontName,...
        'FontSize',10);

end

function h = createModernCheck(parent,pos,label,theme)

    h = uicontrol(parent,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',pos,...
        'String',label,...
        'BackgroundColor',get(parent,'BackgroundColor'),...
        'ForegroundColor',theme.fontColor,...
        'FontName',theme.fontName,...
        'FontSize',10,...
        'FontWeight','bold');

end

function createDivider(parent,pos,theme)

    uipanel(parent,...
        'Units','normalized',...
        'Position',pos,...
        'BackgroundColor',theme.border,...
        'BorderType','none');

end


function card = createCard(parent,pos)

    fig = ancestor(parent,'figure');
    theme = getappdata(fig,'theme');

    card = uipanel(parent,...
        'Units','normalized',...
        'Position',pos,...
        'BackgroundColor',theme.surface,...
        'BorderType','line',...
        'HighlightColor',theme.border,...
        'ShadowColor',theme.border);

end

function browseModelFile(editBox)
    global ddfullpath
    
    fig = resolveGuiFig();
    setStatus(fig, 'Loading Main Model...')
    [file, path] = uigetfile('*.mdl', 'Select Main Model File');
    if isequal(file, 0), return; end
    

	
    fullPath = fullfile(path, file);
    [ddpath,ddfile_name,~] = fileparts(fullPath);
    ddfullpath = [ddpath,'\',ddfile_name,'.dd'];

    set(editBox, 'String', fullPath);

    fig = ancestor(editBox,'figure');
    setappdata(fig,'mainModelPath', fullPath);
    pushWS(fig,'mainModelPath',fullPath);
    setStatus(fig, 'Ready')
    % open_system(fullPath);
end

function showSubmoduleTree(mainModelBox, submoduleBox, fig)
 
    
    %------------------------------------------------------------
    % Get main model path
    %------------------------------------------------------------
	fig = resolveGuiFig();
	
    modelPath = get(mainModelBox,'String');

    if isempty(modelPath)
        modelPath = getappdata(fig,'mainModelPath');
    end
 
    if isempty(modelPath)
        msgbox('Please select a main model first.','Error');
        return;
    end
 
    %------------------------------------------------------------
    % Load model if required
    %------------------------------------------------------------
    [~, modelName] = fileparts(modelPath);
    if ~bdIsLoaded(modelName)
        load_system(modelPath);
    end
 
    %------------------------------------------------------------
    % Remove old panel if exists
    %------------------------------------------------------------
    oldPanel = findobj(fig,'Tag','SubmoduleTreePanel');
    if ishandle(oldPanel)
        delete(oldPanel);
    end
 
    %------------------------------------------------------------
    % Panel placement (Right side)
    %------------------------------------------------------------
    treePanel = uipanel('Parent', fig,'Units','normalized','Position',[0.70 0.33 0.25 0.25],'Tag','SubmoduleTreePanel');
 
    %------------------------------------------------------------
    % Create root node
    %------------------------------------------------------------
    setStatus(fig, 'Analysing Main Model for submodules...');

    rootNode = uitreenode('v0', modelName, modelName, [], false);
    buildTree(modelName, rootNode);
 
    %------------------------------------------------------------
    % Create Java UITree for MATLAB 2016b
    %------------------------------------------------------------
    [jTree, treeContainer] = uitree('v0','Root',rootNode);
    setStatus(fig, 'Ready');
    set(treeContainer,'Parent',treePanel);
    set(treeContainer,'Units','pixels','Position',[1 1 200 400]);
 
    resizeTree();
 
    %------------------------------------------------------------
    % Selection callback
    %------------------------------------------------------------
    set(jTree,'NodeSelectedCallback',@treeSelection);
 
    %------------------------------------------------------------
    % Resize handling
    %------------------------------------------------------------
    treePanel.SizeChangedFcn = @(~,~) resizeTree();
 
    %------------------------------------------------------------
    % ??? NEW: Close panel when clicking outside ???
    %------------------------------------------------------------
    fig.WindowButtonDownFcn = @(src,event)closePanelIfClickedOutside();
 
    drawnow;
 
 
    %============================================================
    % Nested Functions
    %============================================================
 
    function resizeTree()
        try
            if ishandle(treeContainer) && ishandle(treePanel)
                oldUnits = treePanel.Units;
                treePanel.Units = 'pixels';
                pos = treePanel.Position;
                set(treeContainer,'Position',[1 1 pos(3)-2 pos(4)-2]);
                treePanel.Units = oldUnits;
            end
        catch
        end
    end
 
    %------------------------------------------------------------
    %  NEW: Close panel on outside click 
    %------------------------------------------------------------
    function closePanelIfClickedOutside()
        try
            if ~ishandle(treePanel)
                return;
            end
 
            cursorPoint = get(fig,'CurrentPoint');   % click location in figure
 
            % panel pixel position
            oldUnits = treePanel.Units;
            treePanel.Units = 'pixels';
            panelPos = treePanel.Position;
            treePanel.Units = oldUnits;
 
            x = cursorPoint(1);
            y = cursorPoint(2);
 
            inside = x >= panelPos(1) && x <= panelPos(1)+panelPos(3) && y >= panelPos(2) && y <= panelPos(2)+panelPos(4);
 
            if ~inside
                delete(treePanel);  
            end
        catch
        end
    end
 
    %------------------------------------------------------------
    % Recursive buildTree
    %------------------------------------------------------------
    function buildTree(parentPath, parentNode)
        subsystems = find_system(parentPath,'SearchDepth',1,'FollowLinks','on','LookUnderMasks','all','BlockType','SubSystem');
 
        subsystems = setdiff(subsystems,parentPath);
 
        for k = 1:numel(subsystems)
            name = get_param(subsystems{k},'Name');
            linkStatus = get_param(subsystems{k},'LinkStatus');
 
            if strcmpi(linkStatus,'resolved')
                label = [name ' [Link]'];
            else
                label = name;
            end
 
            child = uitreenode('v0',subsystems{k},label,[],false);
            parentNode.add(child);
            buildTree(subsystems{k},child);
        end
    end
 
    %------------------------------------------------------------
    % handle selection
    %------------------------------------------------------------
    function treeSelection(~, event)
        try
            node = event.getCurrentNode;
            selectedPath = char(node.getValue);
 
            set(submoduleBox,'String',selectedPath);
            setappdata(fig,'submodulePath',selectedPath);
            pushWS(fig,'submodulePath',selectedPath);
 
            disp(['Selected submodule: ', selectedPath]);
        catch ME
            disp(['Tree error: ' ME.message]);
        end
    end

 
end

function browseSavePath(editBox)

	fig = resolveGuiFig();
    setStatus(fig, 'Adding Save Path...');
    
    folder = uigetdir(pwd, 'Select Folder to Save');
    if folder == 0, return; end
	
    set(editBox, 'String', folder);
    fig = ancestor(editBox,'figure');
    setappdata(fig,'savePath', folder);
    pushWS(fig,'savePath',folder);
    setStatus(fig, 'Ready');
	
end

function saveInfo(mainBox, subBox, saveBox)

    % -------------------------------------------------
    % Resolve GUI figure
    % -------------------------------------------------
    fig = ancestor(mainBox,'figure');
    setStatus(fig,'Saving Info...');

    xmlFile = getappdata(fig,'mtcdXlsPath');

    if isempty(xmlFile)
        errordlg('No XML file selected.');
        setStatus(fig,'Ready');
        return;
    end

    logFile = fullfile(fileparts(xmlFile), 'commandLog.txt');

    % -------------------------------------------------
    % Read values from GUI / appdata
    % -------------------------------------------------
    mainModel = getUIOrAppdata(fig, mainBox, 'mainModelPath');
    submodule = getUIOrAppdata(fig, subBox,  'submodulePath');
    savePath  = getUIOrAppdata(fig, saveBox, 'savePath');

    commandLog(logFile, 'Main Model   -> %s', mainModel);
    commandLog(logFile, 'Submodule    -> %s', submodule);
    commandLog(logFile, 'Save Path    -> %s', savePath);
    commandLog(logFile, 'XML File     -> %s', xmlFile);

    % -------------------------------------------------
    % Validation
    % -------------------------------------------------
    if isempty(mainModel) || isempty(submodule) || isempty(savePath)
        errordlg('Main Model, Submodule and Save Path are required.');
        setStatus(fig,'Ready');
        return;
    end

    if exist(xmlFile,'file') ~= 2
        errordlg('XML file not found. Please select a valid XML file.');
        setStatus(fig,'Ready');
        return;
    end

    % -------------------------------------------------
    % UPDATE XML FILE
    % -------------------------------------------------
    try
        commandLog(logFile, 'Updating model-info in XML file...');

        % Load XML
        doc = xmlread(xmlFile);

        % Find or create <model-info>
        modelInfoList = doc.getElementsByTagName('model-info');

        if modelInfoList.getLength > 0
            modelInfo = modelInfoList.item(0);
        else
            modelInfo = doc.createElement('model-info');
            doc.getDocumentElement.appendChild(modelInfo);
        end

        % ---- Main Model ----
        nodeList = modelInfo.getElementsByTagName('main-model');
        if nodeList.getLength > 0
            node = nodeList.item(0);
        else
            node = doc.createElement('main-model');
            modelInfo.appendChild(node);
        end
        node.setAttribute('info', char(mainModel));

        % ---- Submodule ----
        nodeList = modelInfo.getElementsByTagName('submodule');
        if nodeList.getLength > 0
            node = nodeList.item(0);
        else
            node = doc.createElement('submodule');
            modelInfo.appendChild(node);
        end
        node.setAttribute('info', char(submodule));

        % ---- Save Path ----
        nodeList = modelInfo.getElementsByTagName('save-path');
        if nodeList.getLength > 0
            node = nodeList.item(0);
        else
            node = doc.createElement('save-path');
            modelInfo.appendChild(node);
        end
        node.setAttribute('info', char(savePath));

        % Save XML
        xmlwrite(xmlFile, doc);

        commandLog(logFile, 'Model info successfully updated in XML.');

    catch ME
        commandLog(logFile, 'ERROR: %s', ME.message);
        errordlg(['Error writing XML file: ' ME.message], 'XML Error');
        setStatus(fig,'Ready');
        return;
    end

    % -------------------------------------------------
    % SAVE MAT FILE
    % -------------------------------------------------
    try
        dataFolder = dir(fullfile(fileparts(xmlFile), '*_data'));

        if ~isempty(dataFolder)
            dataFolderPath = fullfile(dataFolder(1).folder, dataFolder(1).name);
            matFile = fullfile(dataFolderPath,'model_info.mat');

            main_model_name  = mainModel; %#ok<NASGU>
            frame_model_path = submodule; %#ok<NASGU>
            frame_path       = savePath;  %#ok<NASGU>

            save(matFile,'main_model_name','frame_model_path','frame_path');
        end
    catch
        % optional: silent or log
    end

    % -------------------------------------------------
    % USER FEEDBACK
    % -------------------------------------------------
    msgbox({ ...
        'Information saved successfully.', ...
        ['XML File: ', xmlFile], ...
        'Model info updated in XML'}, ...
        'Success');

    setStatus(fig,'Ready');
end

function runFrameCreation(mainBox, subBox, mtcdXlsBox, testSeqBox, savePathBox)
    fig = resolveGuiFig();

    main_model_name  = getUIOrAppdata(fig, mainBox, 'mainModelPath'); 
    [~, main_model_name, ~] = fileparts(main_model_name);

    frame_model_path = getUIOrAppdata(fig, subBox, 'submodulePath');
    frame_path       = getUIOrAppdata(fig, savePathBox, 'savePath');

    if isempty(main_model_name) || isempty(frame_model_path)
        msgbox('Please fill Main Model and Submodule fields.', 'Error');
        return;
    end

    excel_path = getUIOrAppdata(fig, mtcdXlsBox, 'mtcdXlsPath'); %#ok<NASGU>
    if ~isempty(testSeqBox) && ishandle(testSeqBox)
        select_testseq_frm_GUI = get(testSeqBox,'String'); %#ok<NASGU>
    end

    pushWS(fig,'main_model_name',main_model_name);
    pushWS(fig,'frame_model_path',frame_model_path);
    pushWS(fig,'frame_path',frame_path);
  
    try
        [frame_gen_flag, final_slx_path] = Frame_Creation1(main_model_name, frame_model_path, frame_path);
        load('frame_info.mat');
        msgbox('Frame generation completed.', 'Success');
        pushWS(fig,'slxFlag',frame_gen_flag);
        pushWS(fig,'slxFilePath',final_slx_path);
    catch ME
        msgbox(['Frame generation failed: ', ME.message], 'Error', 'error');
    end
   % pull_base_vars_into_caller()
end

function openSLXFile()
    fig = resolveGuiFig();
    setStatus(fig, 'Opening Test Frame...')
%     excelFile = getappdata(fig,'mtcdXlsPath');
%     logFile = fullfile(fileparts(excelFile), 'commandLog.txt');

    [file, path] = uigetfile('*.slx', 'Select SLX File');
    if isequal(file, 0), return; end
    
   
    slxFilePath = fullfile(path, file);
    
    try
        % commandLog(logFile, 'Trying to open Test Frame -> %s', slxFilePath);
        open_system(slxFilePath);
        % commandLog(logFile, 'Test Frame opened');
    catch ME
        % commandLog(logFile, 'ERROR: %s', ME.message);
    end
    
    setappdata(fig, 'slxFlag', true);
    setappdata(fig, 'slxFilePath', slxFilePath);

    pushWS(fig,'slxFlag',true);
    pushWS(fig,'slxFilePath',slxFilePath);

    msgbox(['SLX file opened: ', slxFilePath], 'Success');
    setStatus(fig, 'Ready')
end

function browseXLS(editBox)
    % -------------------------------------------------
    % Resolve GUI figure
    % -------------------------------------------------
    fig = ancestor(editBox,'figure');
    setStatus(fig,'Loading XML File...');

    % -------------------------------------------------
    % Select XML file ONLY
    % -------------------------------------------------
    [file, path] = uigetfile({'*.xml','XML Files'}, ...
                             'Select XML File');
    if isequal(file,0)
        setStatus(fig,'Ready');
        return;
    end

    fullPath = fullfile(path,file);

    % Update UI
    if ishandle(editBox)
        set(editBox,'String', fullPath);
    end

    % Store path
    setappdata(fig,'mtcdXlsPath', fullPath);
    pushWS(fig,'mtcdXlsPath', fullPath);

    logFile = fullfile(path, 'commandLog.txt');

    % -------------------------------------------------
    % READ TEST CASES FROM XML
    % -------------------------------------------------
    testSeqList = getappdata(fig, 'testSeqList');

    if ~isempty(testSeqList) && ishandle(testSeqList)
        set(testSeqList, 'Enable', 'on');
    end

    try
        commandLog(logFile, 'Loading XML file... %s', fullPath);

        doc = xmlread(fullPath);
        testCases = doc.getElementsByTagName('test-case');
        n = testCases.getLength;

        testCaseNames = {};
        testCaseIDs   = {};
        testCaseMap   = containers.Map;

        for i = 0:n-1
            node = testCases.item(i);

            tc_id   = char(node.getAttribute('test-case-id'));
            tc_name = char(node.getAttribute('test-case-name'));

            if ~isempty(tc_id) && ~isempty(tc_name)
                testCaseNames{end+1,1} = tc_name; %#ok<AGROW>
                testCaseIDs{end+1,1}   = tc_id;   %#ok<AGROW>
                testCaseMap(tc_name)   = tc_id;
            end
        end

        if isempty(testCaseNames)
            msgbox('No test cases found in XML.', 'Info');
        else
            
            set(testSeqList, 'String', testCaseNames);
            set(testSeqList, 'Max', length(testCaseNames));
            
            setappdata(fig, 'testSeqListStored', testCaseNames);
            pushWS(fig, 'testSeqListStored', testCaseNames);
            
%             setappdata(fig,'selectedTestSeqList',selectedList);
%             pushWS(fig, 'selectedTestSeqList', selectedList);
%             
            setappdata(fig, 'testCaseNames', testCaseNames);
            setappdata(fig, 'testCaseIDs', testCaseIDs);
            setappdata(fig, 'testCaseMap', testCaseMap);

            pushWS(fig, 'testCaseMap', testCaseMap);

            commandLog(logFile, ...
                'XML loaded: %d test cases found.', ...
                length(testCaseNames));
        end

    catch ME
        commandLog(logFile, 'ERROR: %s', ME.message);
        errordlg(['Error reading XML: ' ME.message], 'XML Error');
        setStatus(fig,'Ready');
        return;
    end

    % -------------------------------------------------
    % READ MODEL INFO FROM XML
    % -------------------------------------------------
    try
        commandLog(logFile, 'Reading model-info from XML');
        doc = xmlread(fullPath);
        modelInfoList = doc.getElementsByTagName('model-info');

        if modelInfoList.getLength == 0
            error('No <model-info> tag found.');
        end

        modelInfo = modelInfoList.item(0);

        % ---- Main Model ----
        mainModelNode = modelInfo.getElementsByTagName('main-model');
        if mainModelNode.getLength > 0
            mainModel = char(mainModelNode.item(0).getAttribute('info'));
        else
            mainModel = '';
        end
    
        % ---- Submodule ----
        submoduleNode = modelInfo.getElementsByTagName('submodule');
        if submoduleNode.getLength > 0
            submodule = char(submoduleNode.item(0).getAttribute('info'));
        else
            submodule = '';
        end

        % ---- Save Path ----
        savePathNode = modelInfo.getElementsByTagName('save-path');
        if savePathNode.getLength > 0
            savePath = char(savePathNode.item(0).getAttribute('info'));
        else
            savePath = '';
        end

        commandLog(logFile, 'Main Model: %s', mainModel);
        commandLog(logFile, 'Submodule: %s', submodule);
        commandLog(logFile, 'Save Path: %s', savePath);

    catch ME
        commandLog(logFile, 'ERROR: %s', ME.message);
        errordlg(['Error reading model-info: ' ME.message], 'XML Error');
        setStatus(fig,'Ready');
        return;
    end

    % -------------------------------------------------
    % STORE VALUES
    % -------------------------------------------------
    setappdata(fig,'mainModelPath', mainModel);
    setappdata(fig,'submodulePath', submodule);
    setappdata(fig,'savePath', savePath);

    pushWS(fig,'mainModelPath', mainModel);
    pushWS(fig,'submodulePath', submodule);
    pushWS(fig,'savePath', savePath);

    % -------------------------------------------------
    % UPDATE UI SAFELY
    % -------------------------------------------------
    safeSetEdit(fig,'mainModelPathBox', mainModel);
    safeSetEdit(fig,'submoduleBox',     submodule);
    safeSetEdit(fig,'savePathBox',      savePath);

    setStatus(fig,'XML loaded successfully');

end

function loadTestCases(mtcdXmlBox, testSeqBox, savePathBox, data_found_flag)

    fig = resolveGuiFig();

    % -------------------------------------------------
    % Paths
    % -------------------------------------------------
    xml_path = getUIOrAppdata(fig, mtcdXmlBox, 'mtcdXlsPath');

    if isempty(xml_path)
        msgbox('Please select XML file first.','Error');
        return;
    end

    logFile = fullfile(fileparts(xml_path), 'commandLog.txt');

    frame_path = getUIOrAppdata(fig, savePathBox, 'savePath');

    [~, submodule_name, ~] = fileparts(getappdata(fig,'submodulePath'));

    % -------------------------------------------------
    % Copy XML into Test Folder
    % -------------------------------------------------
    targetFolder = fullfile(frame_path, ['Test_' submodule_name]);

    if exist(targetFolder, 'dir') ~= 7
        mkdir(targetFolder);
    end

    [~, name, ext] = fileparts(xml_path);
    targetFile = fullfile(targetFolder, [name ext]);

    if ~strcmp(fileparts(xml_path), targetFolder)
        copyfile(xml_path, targetFolder);
        xml_path = targetFile;
    end

    setappdata(fig,'mtcdXlsPath', xml_path);

    % -------------------------------------------------
    % Selected Test Seqs
    % -------------------------------------------------
    if ishandle(testSeqBox)
        selectedSeqs = get(testSeqBox,'String');
    else
        selectedSeqs = {};
    end

    pushWS(fig,'selectedSeqs',selectedSeqs);

    % -------------------------------------------------
    % Step Time Validation
    % -------------------------------------------------
    stepTimeBox = getappdata(fig,'stepTimeBox');
    timestepStr = strtrim(get(stepTimeBox,'String'));

    if isempty(timestepStr)
        errordlg('Step Time is mandatory.', 'Missing Step Time');
        return;
    end

    timestep = str2double(timestepStr);

    if isnan(timestep) || timestep <= 0
        errordlg('Step Time must be a positive number.', ...
                 'Invalid Step Time');
        return;
    end

    % -------------------------------------------------
    % DATA FOLDER
    % -------------------------------------------------
    dataPath = dir(fullfile(fileparts(xml_path), '*_data'));

    if isempty(dataPath)
        errordlg('No *_data folder found next to XML file.');
        return;
    end

    dataFolderPath = fullfile(dataPath(1).folder, dataPath(1).name);

    % -------------------------------------------------
    % LOAD TEST CASES FROM XML (ONLY)
    % -------------------------------------------------
    try
        commandLog(logFile,'Loading Test Cases from XML: %s', xml_path);
        build_from_xml(xml_path, timestep, dataFolderPath);
        commandLog(logFile,'Test Cases loaded successfully');
        msgbox('Test cases loaded successfully.','Success');
    catch ME
        commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(['Failed to load test cases: ', ME.message],'Error','error');
    end

    % -------------------------------------------------
    % MOVE .MAT FILES
    % -------------------------------------------------
    mat_folder = fullfile(targetFolder, 'mat_file');

    if exist(mat_folder,'dir') ~= 7
        mkdir(mat_folder);
    end

    files = dir(fullfile(targetFolder, '*.mat'));

    for k = 1:length(files)
        src = fullfile(targetFolder, files(k).name);
        dst = fullfile(mat_folder, files(k).name);

        try
            movefile(src, dst);
        catch
            movefile(src, dst, 'f');
        end
    end

end

function loadTxtParameters(fig)
    % Open file dialog
    [file, path] = uigetfile('*.txt', 'Select Parameter File');
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    % If cancelled
    if isequal(file,0)
        return;
    end

    fullFilePath = fullfile(path, file);

    try
        commandLog(logFile, 'Pushing the parameters to base workspace from %s', fullFilePath);
        push_paramters_to_workspace(fullFilePath);
        setStatus(fig, ['Loaded parameters: ', file]);
        commandLog(logFile, 'Parameters pushed to base workspace.');
    catch ME
        commandLog(logFile, 'ERROR: %s', ME.message);
        errordlg(['Error loading parameters: ' ME.message], 'Error');
    end
end

function onTestSeqDoubleClick(fig, src)

    if ~strcmp(get(fig,'SelectionType'),'open')
        return;
    end

    allSeqs = get(src,'String');
    idx     = get(src,'Value');

    if isempty(idx), return; end
    newSeqs = allSeqs(idx);

    rightBox = getappdata(fig,'selectedTestSeqList');
    existing = get(rightBox,'String');

    if isempty(existing)
        existing = {};
    end

    combined = unique([existing(:); newSeqs(:)], 'stable');

    set(rightBox,'String', combined);
    pushWS(fig,'TestseqID', combined);
end

function selectAllSeqs(fig)

    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    
    leftBox  = getappdata(fig, 'testSeqList');          % Test Seq IDs list
    rightBox = getappdata(fig, 'selectedTestSeqList');  % Selected list

    allLeft = get(leftBox, 'String');   % All items from left
    test_cases = strjoin(allLeft, ', ');
    if isempty(allLeft)
        return;
    end

    % Add all sequences to right box (unique + preserve order)
    set(rightBox, 'String', unique(allLeft, 'stable'));
    commandLog(logFile, 'Selecting all the available Test Cases %s', test_cases);
    % save to workspace
    pushWS(fig, 'TestseqID', allLeft);
end

function deleteSelectedTS(fig)

    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');

    rightBox = getappdata(fig,'selectedTestSeqList');
    if isempty(rightBox) || ~ishandle(rightBox)
        return;
    end

    items = get(rightBox,'String');
   
    
    idx   = get(rightBox,'Value');

    if isempty(items) || isempty(idx)
        return;
    end

    deleting_test_cases = items(idx);
    items(idx) = [];
    
     test_cases = strjoin(deleting_test_cases, ', ');
    set(rightBox,'String', items, 'Value', []);
    commandLog(logFile, 'Deleting the selected Test Cases %s', test_cases);
    
    pushWS(fig,'TestseqID', items);
end

function executeSimulation(mtcdXlsBox,savePathBox, submodule)

    fig = resolveGuiFig();
    TestseqID = {};
    excel_path = getUIOrAppdata(fig, mtcdXlsBox, 'mtcdXlsPath');
    frame_path = getUIOrAppdata(fig, savePathBox, 'savePath'); %#ok<NASGU>
    testCaseMap = getappdata(fig, 'testCaseMap');
    
    test_dir = fileparts(excel_path);
    slx_frame_path = dir(fullfile(test_dir, '*.slx'));
    
     % ---------- PRIORITY 1: RIGHT LIST ----------
    rightBox = getappdata(fig,'selectedTestSeqList');
    if ~isempty(rightBox)
        TestseqNames = get(rightBox,'String');
    else
        TestseqNames = {};
    end
    

    for i=1:length(TestseqNames)
        TestseqID{end+1} = testCaseMap(TestseqNames{i});
    end
    TestseqID = TestseqID';
    % ---------- FALLBACK: MANUAL ----------
    
    if isempty(TestseqID)
        manualSeq = strtrim(getappdata(fig,'manualTestSeqText'));
        if ~isempty(manualSeq)
            TestseqID = strsplit(manualSeq,{',',';',' '});
            TestseqID = TestseqID(~cellfun('isempty',TestseqID));
        end
    end
    pushWS(fig,'TestseqID',TestseqID);

    if isempty(excel_path) || isempty(TestseqID)
        msgbox('Please select MTCD XLS path and enter at least one TestSeq ID manually.', 'Error');
        return;
    end
    frame_opened=0;
    timestep = 0.001;
    [~,submodule_name,~]=fileparts(getUIOrAppdata(fig, savePathBox, 'submodulePath'));
    folder_name=[frame_path,'\',['Test_',submodule_name]];
    expecting_frame = [folder_name,'\',['Frame_',submodule_name,'_tl']];
    frame_name=['Test_Frame_',submodule_name,'_tl'];
    bds = find_system('type','block_diagram');
    for k = 1:numel(bds)
        modelName = bds{k};
       if strcmp(modelName,frame_name)
        frame_opened=1;
       end
    end
  
    
    if  ~frame_opened
        msgbox('No SLX file was opened.', 'Warning');
        return;
    end


    milChk = getappdata(fig,'milChk');
    milChk = milChk.Value;
    silChk = getappdata(fig,'silChk');
    silChk = silChk.Value;
    % try
        fcn_Simulate_frame(excel_path,TestseqID, milChk, silChk, frame_name);
    % catch ME
    %     msgbox(ME.message, 'Error')
    % end
end

function generateCodeCallback(fig)

    setStatus(fig, 'Generating code...');

    try
        % Retrieve frame model info from appdata
        excel_path = getappdata(fig, 'mtcdXlsBox');
        slx_path = dir(fullfile(fileparts(excel_path.String), '*.slx'));
        temp_test_frame = slx_path.name;
        [~, frame_name, ext] = fileparts(temp_test_frame);

        % ---- Run your code generation function ----
        ok = generate_code(frame_name);

        % ---- Display result to user ----
        if ok
            msgbox('Code generation successful.', 'Success', 'modal');
            setStatus(fig, 'Code generation completed');
        else
            errordlg('Code generation failed. Check build logs.', 'Build Failed');
            setStatus(fig, 'Code generation failed');
        end

    catch ME
        errordlg(['Error during code generation: ' ME.message], 'Error');
        setStatus(fig, 'Error');
    end
    setStatus(fig, 'Ready');
end

function safeSetEdit(fig, key, value)

    h = getappdata(fig, key);

    if ~isempty(h) && ishandle(h)
        set(h, 'String', value);
    end
end

function populateTsFolders(fig)

    ddFolders = getappdata(fig,'sim_ddFolders');
    if isempty(ddFolders) || ~ishandle(ddFolders)
        return;
    end

    mtcdPath = getappdata(fig,'mtcdXlsPath');
    if isempty(mtcdPath)
        set(ddFolders,'String',{'<No MTCD Path>'},'Value',1);
        return;
    end

    baseDir = fileparts(mtcdPath);

    if exist(baseDir,'dir') ~= 7
        set(ddFolders,'String',{'<Invalid Path>'},'Value',1);
        return;
    end

    d = dir(fullfile(baseDir,'TS_*'));
    d = d([d.isdir]);

    if isempty(d)
        set(ddFolders,'String',{'<No TS Folders>'},'Value',1);
    else
        set(ddFolders,'String',{d.name},'Value',1);
    end
end

function result = generate_code(frame_name)
    fig = resolveGuiFig();
    setStatus(fig, 'Generating Code...');
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    commandLog(logFile, 'Code Generation Started.');
    
    baseDir = fileparts(excelFile);
    cd(baseDir);
   
    % deleting the previous paths from DD and and generates the code.
    hSubsystem = dsdd('Find', '/Subsystems', 'ObjectKind', 'Subsystem');
    for i = 1:length(hSubsystem)
        dsdd('Delete', hSubsystem(i));
    end
    % SubsystemWorkingDirectory = dsdd('GetSubsystemInfoWorkingDirectory', '');
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
    setStatus(fig, 'Ready');
end



function onPlotSignal(ddFolders, ddSignals, ddCompare)

    fig = resolveGuiFig();

    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    
    % --- Extract TS folder ---
    folders = get(ddFolders,'String');
    fIdx    = get(ddFolders,'Value');
    testCaseName = folders{fIdx};

    % --- Extract Signal ---
    signals = get(ddSignals,'String');
    sIdx    = get(ddSignals,'Value');
    signalName = signals{sIdx};

    % --- Extract Mode SAFELY ---
    modes = get(ddCompare,'String');      % cell array
    mIdx  = get(ddCompare,'Value');       % scalar index
    mode  = modes{mIdx};                  % char vector

    % Defensive conversion (optional but safe)
    mode = char(mode);

    % --- Resolve base folder ---
    mtcdPath = getappdata(fig,'mtcdXlsPath');
    baseDir  = fileparts(mtcdPath);

    % --- Mode logic (COMPLETE) ---
    mil = 0;
    sil = 0;

    switch mode
        case 'MIL'
            mil = 1;
            sil = 0;

        case 'SIL'
            mil = 0;
            sil = 1;

        case 'MIL vs Expected'
            mil = 1;
            sil = 0;

        case 'MIL vs SIL'
            mil = 1;
            sil = 1;

        otherwise
            errordlg(['Unknown mode: ' mode],'Error');
            return;
    end
    
    try
        % --- Call backend plot function ---
        plot_signal_from_mat(baseDir, testCaseName, signalName, mil, sil);
    catch ME
        msgbox(ME.message, 'Warning');
        commandLog(logFile, 'ERROR: %s', ME.message);
    end
    
end
function onSignalChanged(fig)

    ddSignals = getappdata(fig,'sim_ddSignals');
    if isempty(ddSignals) || ~ishandle(ddSignals)
        return;
    end

    mtcdPath = getappdata(fig,'mtcdXlsPath');
    if isempty(mtcdPath)
        set(ddSignals,'String',{'<No MTCD Path>'},'Value',1);
        return;
    end

    baseDir = fileparts(mtcdPath);
    dataDir = dir(fullfile(baseDir, '*_data'));

    if isempty(dataDir)
        set(ddSignals,'String',{'<No Data Folder>'},'Value',1);
        return;
    end

    dataFolder = fullfile(dataDir(1).folder, dataDir(1).name);
    outports_file = fullfile(dataFolder, 'outports.json');

    if ~exist(outports_file, 'file')
        set(ddSignals,'String',{'<No Outports File>'},'Value',1);
        return;
    end

    rawText = strtrim(fileread(outports_file));
    if isempty(rawText) || strcmp(rawText,'{}')
        set(ddSignals,'String',{'<No signals>'},'Value',1);
        return;
    end

    try
        data = jsondecode(rawText);
    catch
        set(ddSignals,'String',{'<Invalid JSON>'},'Value',1);
        return;
    end

    signals = {};

    for i = 1:numel(data)

        if isfield(data(i),'signal')
            signals{end+1} = strtrim(data(i).signal); %#ok<AGROW>
        end

    end

    if isempty(signals)
        set(ddSignals,'String',{'<No signals>'},'Value',1);
    else
        set(ddSignals,'String',signals,'Value',1);
    end

end

function generateHTMLReport(path)

    fig = resolveGuiFig();
    setStatus(fig, 'Generating HTML Report...');
%     excelFile = getappdata(fig,'mtcdXlsPath');
%     logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
%     
    % ---------------------------------------------------------
    % Normalize input (single -> cell array)
    % ---------------------------------------------------------
    if ischar(path)
        excelPaths = {path};
    elseif iscell(path)
        excelPaths = path;
    else
        error('Invalid input: path must be a string or cell array of strings.');
    end

    templatesDir = [fileparts(mfilename('fullpath')), '\', 'ConsolidatedReportTemplates'];  % <<< KEEP AS IS
    
    try
        indexHtmlPath = build_full_report(excelPaths, templatesDir);
        % commandLog(logFile, 'HTML Reports generated and saved at %s', indexHtmlPath);
        
        msgbox('Report generated successfully', 'Success');

    catch ME
        errordlg(ME.message, 'Report Error');
        setStatus(fig, 'Report');
        return;
    end

    try
        web(indexHtmlPath, '-browser');
    catch
        warning('Could not open HTML report automatically.');
    end
    setStatus(fig, 'Report');
end

function addExcelCallback(fig)

    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
   
    [f,p] = uigetfile({'*.xml;','Excel Files'}, ...
                      'Select Excel File');
    if isequal(f,0)
        return;
    end

    excelPath = fullfile(p,f);
    commandLog(logFile, 'Selected excel for Batch Run %s', excelPath);
    paths = getappdata(fig,'excelPathList');
    paths{end+1} = excelPath;
    setappdata(fig,'excelPathList',paths);

    if isappdata(fig,'excelPathListBox')
        lb = getappdata(fig,'excelPathListBox');
        if isgraphics(lb)
            set(lb,'String',paths);
        end
    end
    
end

function deleteSelectedExcel(fig)

    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    
    lb    = getappdata(fig,'excelPathListBox');
    paths = getappdata(fig,'excelPathList');
    idx   = getappdata(fig,'selectedExcelIdx');

    if isempty(idx)
        return;
    end

    deleting_excels = paths(idx);
    paths(idx) = [];
    for i=1:length(deleting_excels)
        commandLog(logFile, 'Deleting excel from Batch Run %s', deleting_excels{i});
    end
    
    setappdata(fig,'excelPathList',paths);

    set(lb,'String',paths);
    set(lb,'Value',[]);

    setappdata(fig,'selectedExcelIdx',[]);
    set(getappdata(fig,'deleteExcelBtn'),'Enable','off');
end

function onExecuteSimulation(fig)

    excel_paths = getappdata(fig,'excelPathList');
   
    excelFile = getappdata(fig,'mtcdXlsPath');
    logFile = fullfile(fileparts(excelFile), 'commandLog.txt');
    
    if isempty(excel_paths)
        uialert(fig,...
            'No Excel files added. Please add at least one Excel file.', ...
            'Execute Simulation');
        return;
    end

    % -------------------------------------------------
    % CALL YOUR USER-DEFINED FUNCTION HERE
    % -------------------------------------------------
    % Example:
    try
        % commandLog(logFile, 'Started Execution for Batch Run.');
        batch_run(excel_paths);
        % commandLog(logFile, 'Batch Run completed sucessfully.');
    catch ME
        % commandLog(logFile, 'ERROR: %s', ME.message);
        msgbox(ME.message, 'Error');
    end
    
end

function onAutomaticBatchRun(fig)

    % Select root folder
    rootDir = uigetdir(pwd, 'Select Root Folder for Batch Run');
    if isequal(rootDir,0)
        return;
    end

    % Confirmation popup
    choice = questdlg( ...
        sprintf('Selected folder:\n\n%s\n\nDo you want to continue with Batch Run?', rootDir), ...
        'Confirm Batch Run', ...
        'Continue with Batch Run', ...
        'Generate only Reports', ...
        'Cancel', ...
        'Continue with Batch Run');

    if strcmp(choice,'Cancel')
        setStatus(fig,'Batch run cancelled');
        return;
    end

    setStatus(fig,'Scanning folders for Excel files...');

    % Collect Excel paths
    excelPaths = getAllExcelFilesRecursive(rootDir);
    
    if strcmp(choice,'Generate only Reports')
        setStatus(fig,'Generating Consolidated reports for Batch Run');
        generateHTMLReport(excelPaths);
        return;
    end
    
    if isempty(excelPaths)
        errordlg('No valid Test_* folders with matching Excel files found.', ...
                 'Batch Run Error');
        setStatus(fig,'No valid Excel files found');
        return;
    end

    % Store paths
    setappdata(fig,'excelPathList', excelPaths);

    % ? DISPLAY FULL PATHS IN LISTBOX
    listBox = getappdata(fig,'excelPathListBox');
    set(listBox,'String', excelPaths, 'Value', 1);

    % Enable delete button
    delBtn = getappdata(fig,'deleteExcelBtn');
    set(delBtn,'Enable','on');

    setStatus(fig, sprintf('Loaded %d Excel files. Executing...', numel(excelPaths)));

    % Start batch execution
    onExecuteSimulation(fig);
end

function onRunTestCases(fig)

    % Step 1: Pick folder
    folderPath = uigetdir(pwd, 'Select Folder Containing XML Test Cases');

    if folderPath == 0
        setStatus(fig,'Folder selection cancelled');
        return;
    end

    % Step 2: Load XML files
    xmlFiles = dir(fullfile(folderPath, '*.xml'));

    if isempty(xmlFiles)
        setStatus(fig,'No XML files found');
        return;
    end

    fileNames = {xmlFiles.name};
    fullPaths = fullfile(folderPath, fileNames);

    % Step 3: Update UI list
    setappdata(fig,'excelPathList', fullPaths);

    listBox = getappdata(fig,'excelPathListBox');
    set(listBox, 'String', fullPaths, 'Value', 1);

    % Step 4: Execute immediately
    try
        perform_full_testcases_batch_run(xmlFiles, fig);
        setStatus(fig, sprintf('Executed %d test cases', numel(fullPaths)));
    catch ME
        setStatus(fig,'Error running test cases');
        disp(ME.message);
    end

end

function excelPaths = getAllExcelFilesRecursive(rootDir)

    excelPaths = {};

    % Get all subfolders
    allDirs = strsplit(genpath(rootDir), pathsep);
    allDirs = allDirs(~cellfun('isempty', allDirs));
    allDirs = sort(allDirs);

    for d = 1:numel(allDirs)

        folderPath = allDirs{d};
        [~, folderName] = fileparts(folderPath);

        % Only process Test_* folders
        if ~startsWith(folderName, 'Test_')
            continue;
        end

        % Get ALL matching Excel files in this folder
        excel_files = dir(fullfile(folderPath, '*_TestCase.xml'));

        % If no files found, skip
        if isempty(excel_files)
            continue;
        end

        % Loop through found files
        for k = 1:length(excel_files)
            fullPath = fullfile(excel_files(k).folder, excel_files(k).name);

            if exist(fullPath, 'file')
                excelPaths{end+1} = fullPath; %#ok<AGROW>
            else
                warning('Expected Excel missing: %s', fullPath);
            end
        end
    end
end

function onExcelPathSelected(fig, src)

    idx = get(src,'Value');
    setappdata(fig,'selectedExcelIdx',idx);

    delBtn = getappdata(fig,'deleteExcelBtn');
    if isempty(idx)
        set(delBtn,'Enable','off');
    else
        set(delBtn,'Enable','on');
    end
end

function runPythonExe()
    exePath = mfilename('fullpath');
    [exePath,~,~] = fileparts(exePath);
    exePath = fullfile(exePath, 'TestCase.exe');

    if isempty(exePath)
        msgbox('Executable not found in current directory.', 'Error');
        return;
    end

    try

       % parfeval(backgroundPool, @system, 2, ['"', exePath, '"']);
        system(['"', exePath, '"']);
        msgbox('Python EXE executed successfully.', 'Success');
    catch ME
        msgbox(['Error running EXE: ', ME.message], 'Error');
    end
end
