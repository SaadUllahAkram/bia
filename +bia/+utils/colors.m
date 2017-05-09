function colors  = colors(cmap, n)
% returns the colors from requested colormaps
% color values range from 0-1
%
% Inputs:
%     mode1: returns requested colormaps
%         cmap (optional): colormap name
%         n (optional): #colors to return
%     mode2: returns colormap showing rank or score
%         cmap: 'scale-' OR 'rank-'
%         n: array containing scores [0-1]
% Outputs:
%     colors: Nx3 color matrix [0-1]
%

if nargin == 0
    cmap = '';
end


if contains(cmap, {'rank-','scale-'})% mode2
    num = length(n);
    if size(n, 2) > 1;  n = n';   end
    
    if contains(cmap,'rank-')
        [~, idx] = sort(n, 'descend');
        if strcmp(cmap, 'rank-red')
            colors = [(1:-1/(num-1):0)', zeros(num, 2)];
        elseif strcmp(cmap, 'rank-redblue')
            colors = [(1:-1/(num-1):0)', zeros(num,1), (0:1/(num-1):1)'];% red-blue
        end
        colors(idx, :) = colors;
    elseif contains(cmap,'scale-')
        if strcmp(cmap, 'scale-red')
            colors = [n, zeros(num, 2)];
        elseif strcmp(cmap, 'scale-redblue')
            colors = [n, zeros(num,1), 1-n];% red-blue
        end
    end
else% mode1
    if strcmp(cmap,'lines')
        colors = lines;
    elseif strcmp(cmap,'prism')
        colors = prism;
    elseif strcmp(cmap, 'r')
        colors = [1 0 0];
    elseif strcmp(cmap, 'g')
        colors = [0 1 0];
    elseif strcmp(cmap, 'b')
        colors = [0 0 1];
    elseif strcmp(cmap, 'y')
        colors = [1 1 0];
    else
        colors = lines;
    end
    
    colors = unique(colors,'rows');
    
    if nargin == 2
        if isempty(n) || n < 1
            n = 1;
        end
        r = ceil(double(n)/size(colors,1));
        colors = repmat(colors, r, 1);
    end
    
end