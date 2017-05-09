function centroids(ax, stats, col, ms, varargin)
% uses "scatter" to draw centroids of objects in current image: 4th+ inputs are passed directly to "scatter"
% scatter can accept and ignore NaN values
% 
% ToDo: Make it draw 3D bboxes on orthogonal images for 3d data: Not priority
% 
% Inputs:
%     ax: axes handle
%     stats : can be a struct or a row (each sample is in a row) matrix [Nx2], remove extra dimensions in case of 3D images
%     col   : color of markers, use "[]" if not using it, it can be a cell array or a matrix in case dots have different color
%     ms    : marker size (36): use "[]" if not using it, it can be a vector in case dots of different size have to be plotted
% 
%     common settings: check out "Scatter Series Properties"
%     Marker ('o'):  '*', 'd' (diamond), 's' (square)
% 

ax = get_axes(ax);

if isstruct(stats)
    cents = bia.convert.centroids(stats);
elseif isnumeric(stats)
    cents = stats;
end
if isempty(cents)
    return;
end

if nargin < 3
    col = [];
end
if nargin < 4
    ms  = [];
end
if isempty(ms)
    ms = 50;% matlab default is 36
end
if isempty(col)
    col = 'r';
end

assert(size(cents, 2) <= 3, 'centroids has 3+ values for each sample, it might need to be transposed')

hold on
scatter(cents(:, 1), cents(:, 2), ms, col, 'filled', 'Parent', ax)
hold off
end