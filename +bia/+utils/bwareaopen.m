function [im, idx_rm] = bwareaopen(im, sz)
% same as bwareaopen but it also removes objects larger than X pixels.
% can accept both labelled image and stats structure
% labels of kept regions remain same.
% 
% Inputs:
%     im: labelled image
%     sz: [min_sz, max_sz], size of valid object range, values > or < than this range are removed.
% Outputs:
%     im : "labelled image" OR "stats" after removal of objects
%     idx_rm : ids of removed regions
% 

assert(length(sz) == 2, '[min_size max_size]')
if isnumeric(im)
    stats = regionprops(im, 'Area', 'PixelIdxList');
elseif isstruct(im)
    stats = im;
end

area = [stats(:).Area];
idx_small = find(area < sz(1));
idx_large = find(area > sz(2));

idx_rm = [idx_small, idx_large];
if isnumeric(im)
    for i=idx_rm
        im(stats(i).PixelIdxList) = 0;% using "PixelIdxList" is much faster, > an order of magnitude for large images
    end
else
    if isfield(stats, 'Centroid')
        set_cent = true;
        dim = length(stats(1).Centroid);
        default_centroid = NaN*ones(1, dim);
    else
        set_cent = false;
    end
    if isfield(stats, 'BoundingBox')
        set_bb = true;
        dim = length(stats(1).BoundingBox)/2;
        default_bb = [0.5*ones(1, dim) zeros(1, dim)];
    else
        set_bb = false;
    end
    
    for i=idx_rm
        stats(i).PixelIdxList = [];
        stats(i).Area = 0;
        if set_cent
            stats(i).Centroid = default_centroid;
        end
        if set_bb
            stats(i).BoundingBox = default_bb;
        end
    end
    im = stats; 
end

end
