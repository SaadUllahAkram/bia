function [handle_fig, handle_ax] = fig(handle_fig, num_subplots, fs, tight, hold_on, dock)
% Usage:
%     fig(handle) : moves the focus to figure "handle" without moving it to foreground
%     fig(handle, ..., 'f') : makes figure FULLSCREEN
%     fig('name') : create a figure, and makes it fullscreen
%     fig(... , num_plots) : creates subplots in the figure
%     
% Usage:
%     [handle_ax, handle_fig] = bia.plot.fig(fig_name_str);
%     [handle_ax, handle_fig] = bia.plot.fig(handle_fig);
%     [handle_ax, handle_fig] = bia.plot.fig(handle_fig, [2, 3]);% to get handles to 6 subplots in the figure
% 
% Inputs:
%     handle_fig   : either "handle" or "name" of a figure
%     num_subplots : [rows, cols] of subplots
%     fs           : maximizes the figure: 'f' or 'fullscreen', else: figure is not maximized
%     tight        : 1-> little space between subplots, 0-> normal spacing between subplots
%     hold_on      : 1-> turn hold on for all subplots, 0-> does nothing
% Outputs:
%     handle_fig : handle of the figure.
%     handle_ax  : handle to axes in a figure: is column array of handles in case of multiple axes (i.e. subplots)
% 

%% parse inputs
if nargin < 1
    handle_fig = '1';
end
if nargin < 2
    num_subplots = 1;
end
if nargin < 3 || strcmp(fs,'f') || fs == 1
    fs = 1;
else
    fs = 0;
end
if nargin < 4
    tight = 1;
end
if nargin < 5
    hold_on = 1;
end
if nargin < 6
    dock = 0;
end

% create new figure
if ischar(handle_fig)
    handle_fig = figure('NumberTitle', 'off', 'Name', handle_fig);
elseif isnumeric(handle_fig)
    handle_fig = figure('NumberTitle', 'off', 'Name', num2str(handle_fig));
    % set(handle_fig,'Visible', 'off');
    % set(0, 'CurrentFigure', handle_fig);
end

if isgraphics(handle_fig, 'figure')
    set(0, 'CurrentFigure', handle_fig);
end
    
if length(num_subplots) == 1
    num_subplots = [num_subplots num_subplots];
end
if length(num_subplots) == 2% multiple plot in the figure
    for i = 1:num_subplots(1)
        for j = 1:num_subplots(2)
            k = num_subplots(2)*(i-1)+j;
            if tight
                handle_ax(k,1) = bia.plot.subplot(num_subplots(1), num_subplots(2), k, handle_fig);
            else
                handle_ax(k,1) = subplot(num_subplots(1), num_subplots(2), k, 'Parent', handle_fig);
            end
        end
    end
% else % only 1 plot in figure
%     while isempty(handle_fig.CurrentAxes)
%         axes(handle_fig);
%     end
%     handle_ax  = handle_fig.CurrentAxes;
end


if hold_on
    for i=1:length(handle_ax)
        hold(handle_ax(i), 'on')
    end
end

if fs
    drawnow
    fullscreen(handle_fig);
end

if nargout == 0
    clear handle_fig handle_ax
end
%set(handle_fig,'Visible', 'on');
if dock
    handle_fig.WindowStyle = 'docked';
end

end

function fullscreen(handle)
frame_h = get(handle,'JavaFrame');
set(frame_h,'Maximized',1);
% set(handle, 'units', 'normalized', 'outerposition', [0 0 1 1]);
end