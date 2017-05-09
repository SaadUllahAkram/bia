function bb(ax, stats, col, line_width, varargin)
% uses "rectangle" to draw bboxes of objects in current image: 4th+ inputs are passed directly to "rectangle"
% bbox : [topLeftCornerPos(x y), sizeOfBbox(w h)]
% rectangle can accept and ignore empty bboxes (i.e. width/height == 0)
% 
% Inputs:
%     ax            : axes handle in which bboxes will be drawn
%     stats         : can be a struct or a row (each sample is in a row) matrix
%     col           : color of markers, use "[]" if not using it, it can be a cell array or a matrix in case dots have different color
%     line_width    : marker size (36): use "[]" if not using it, it can be a vector in case dots of different size have to be plotted
%     varargin      : 'rectangle' options
%     common settings:
%     LineStyle ('-'):  '--', ':'
% 
% 

ax = get_axes(ax);

if isstruct(stats)
    bb = arrayfun(@(x) (x.BoundingBox), stats, 'UniformOutput', false);
elseif isnumeric(stats)
    bb = mat2cell(stats, ones(1,size(stats,1)), 4);
end

if isempty(bb)
    return
end

if nargin < 4
    line_width  = [];
end
if isempty(line_width)
    line_width = 1;% matlab default is 0.5
end

if nargin < 3
    col = [];
end
if isempty(col)
    col = 'r';%repmat({[1 0 0]}, length(bb), 1);
elseif isnumeric(col) && size(col, 2) == 3
    col = mat2cell(col, ones(size(col,1),1), 3);
end

if numel(col) == 1
    cellfun(@(x) rectangle('Parent', ax, 'Position', x, 'EdgeColor', col, 'LineWidth', line_width, varargin{:}), bb)
else
    cellfun(@(x, y) rectangle('Parent', ax, 'Position', x, 'EdgeColor', y, 'LineWidth', line_width, varargin{:}), bb, col)
end
end