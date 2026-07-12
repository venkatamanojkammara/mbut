function fig = resolveGuiFig()
fig = gcbf;
if isempty(fig) || ~ishandle(fig), fig = gcf; end
if isempty(fig) || ~ishandle(fig) || isempty(getappdata(fig,'rightPanel'))
    figs = findall(0,'Type','figure');
    for k = 1:numel(figs)
        if ~isempty(getappdata(figs(k),'rightPanel')), fig = figs(k); return; end
    end
end
end
