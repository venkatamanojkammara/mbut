function ut_setStatus(fig, message, statusType)
%UT_SETSTATUS Update the MBUT application status bar.
%
% Inputs:
%   fig        - Main MBUT application figure handle.
%   message    - Status message displayed in the status bar.
%   statusType - Status category:
%                'ready', 'working', 'success',
%                'warning', or 'error'.

    if nargin < 3 || isempty(statusType)
        statusType = 'ready';
    end

    if nargin < 2 || isempty(message)
        message = '';
    end

    if isempty(fig) || ~ishandle(fig)
        return;
    end

    statusText = getappdata( ...
        fig, ...
        'statusText');

    statusIndicator = getappdata( ...
        fig, ...
        'statusIndicator');

    if ~isempty(statusText) && ishandle(statusText)

        set( ...
            statusText, ...
            'String', ...
            ['  ' message]);

    end

    if ~isempty(statusIndicator) && ishandle(statusIndicator)

        indicatorColor = getStatusColor(statusType);

        set( ...
            statusIndicator, ...
            'ForegroundColor', ...
            indicatorColor);

    end

    applicationState = getApplicationState();

    applicationState.STATUS = message;
    applicationState.STATUS_TYPE = statusType;

    assignin( ...
        'base', ...
        'GUI_STATE', ...
        applicationState);

    drawnow;

end


function indicatorColor = getStatusColor(statusType)
%GETSTATUSCOLOR Return the status indicator color.

    switch lower(statusType)

        case 'working'
            indicatorColor = [0.125 0.350 0.620];

        case 'success'
            indicatorColor = [0.145 0.520 0.330];

        case 'warning'
            indicatorColor = [0.850 0.560 0.120];

        case 'error'
            indicatorColor = [0.720 0.220 0.220];

        otherwise
            indicatorColor = [0.145 0.520 0.330];

    end

end


function applicationState = getApplicationState()
%GETAPPLICATIONSTATE Read GUI_STATE from the MATLAB base workspace.

    try

        applicationState = evalin( ...
            'base', ...
            'GUI_STATE');

        if ~isstruct(applicationState)
            applicationState = struct();
        end

    catch

        applicationState = struct();

    end

end