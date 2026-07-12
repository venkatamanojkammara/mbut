function setStatus(fig,msg)
h=getappdata(fig,'statusText'); if ~isempty(h)&&ishandle(h), set(h,'String',['  ' msg]); drawnow; end
pushWS(fig,'STATUS',msg);
end
