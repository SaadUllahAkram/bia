function ax = get_axes(ax)

if isempty(ax)
    ax = gca;
elseif ~isgraphics(ax, 'axes')
    ax = gca;
end
hold(ax, 'on')
end