function [stats, sz_new] = resize(stats_in, scale, sz, is_props)
% resizes proposal/segmented/tracked stats
%
% todo: ensure each stats{t} has atleast 1 region (can be empty)
% 
% Inputs:
%     stats : cell array of structs
%     scale : scale (scalar) or new_size (1x2 matrix):
%     sz : size of mask images in stats
%     is_props (default:1): 0-> a pixel can have only 1 label, 1-> some pixels may have multiple labels (are proposals)
% Outputs:
%     stats: resized stats
%     sz_new: size after re-sizing
% 

if nargin < 4
    is_props = 1;
end

T = length(stats_in);
stats = stats_in;

dim = 2;

if length(scale) > 1
    sz_new = scale;
    if size(sz_new, 1) == 1
        sz_new = repmat(sz_new, T, 1);
    end
    if size(sz,1) == 1
        sz = repmat(sz, T, 1);
    end
    scale = isequal(sz, sz_new);
else
    if size(unique(sz,'rows'), 1) == 1
        sz = unique(sz,'rows');
        tmp = imresize(zeros(sz), scale);
        sz_new = size(tmp);

        sz = repmat(sz, T, 1);
        sz_new = repmat(sz_new, T, 1);
    else
        parfor t=1:T
            tmp = imresize(zeros(sz(t,:)), scale);
            sz_new(t,:) = size(tmp);
        end
    end
end

if scale ~= 1
    parfor t=1:T
        if is_props
            for k=1:length(stats_in{t,1})
                im = bia.convert.stat2im(stats_in{t,1}(k), sz(t,:));
                im = imresize(im, sz_new(t,1:2), 'nearest');
                stats_k = regionprops(im, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList');
                if isempty(stats_k)
                    stats_k = struct('Area',0,'BoundingBox',[0.5*ones(1,dim) zeros(1,dim)], 'Centroid', NaN(1,dim), 'PixelIdxList', []);
                end
                stats{t,1}(k) = bia.utils.setfields(stats_in{t,1}(k),'Area',stats_k.Area,...
                    'BoundingBox',stats_k.BoundingBox,'Centroid',stats_k.Centroid,'PixelIdxList',stats_k.PixelIdxList);
            end
        else% faster [use only for SEG/TRACKS]
            im = bia.convert.stat2im(stats_in{t,1}, sz(t,:));
            im = imresize(im, sz_new(t,1:2), 'nearest');
            stats_loc = regionprops(im, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList');
            for k=1:length(stats_in{t,1})
                if isempty(stats_loc) || length(stats_loc) < k
                    stats_k = struct('Area',0,'BoundingBox',[0.5*ones(1,dim) zeros(1,dim)], 'Centroid', NaN(1,dim), 'PixelIdxList', []);
                else
                    stats_k = stats_loc(k);
                end
                stats{t,1}(k) = bia.utils.setfields(stats_in{t,1}(k),'Area',stats_k.Area,...
                    'BoundingBox',stats_k.BoundingBox,'Centroid',stats_k.Centroid,'PixelIdxList',stats_k.PixelIdxList);
            end
        end
    end
end

end