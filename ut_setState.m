function ut_setState(fig, key, value)

    setappdata(fig, key, value);

    try
        state = evalin('base', 'GUI_STATE');
        if ~isstruct(state), state = struct(); end
    catch
        state = struct();
    end

    if ~isvarname(key)
        key = matlab.lang.makeValidName(key);
    end
    state.(key) = value;
    assignin('base', 'GUI_STATE', state);
end
