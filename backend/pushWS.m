function pushWS(fig,key,value)
if nargin < 3, value = getappdata(fig,key); end
try, S=evalin('base','GUI_STATE'); if ~isstruct(S), S=struct(); end; catch, S=struct(); end
if ~isvarname(key), key=matlab.lang.makeValidName(key); end
S.(key)=value; assignin('base','GUI_STATE',S);
end
