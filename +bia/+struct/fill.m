function tracks = fill(tracks, K, dim)
% makes stats have same length at each time point by adding default values
%todo: handle 3D

if nargin < 3
    dim = 2;
end
if nargin < 2
    find_k = 1;
elseif isempty(K)
    find_k = 1;
else
    find_k = 0;
end

if iscell(tracks)
    if find_k
        len = cellfun(@(x) length(x), tracks);
        K = max(len);
    end

    T = length(tracks);
    for t=T:-1:1
        tracks{t} = fill_loc(tracks{t}, K, dim);
    end
else
    tracks = fill_loc(tracks, length(tracks), dim);
end

end


function stats = fill_loc(stats,K,dim)
default_centroid = NaN(1, dim);
default_bbox = [0.5*ones(1, dim) zeros(1, dim)];

if length([stats(:).Area]) == K
    return
end
idx = find(arrayfun(@(x) isempty(x.Area), stats))';% find k, which need to be filled
idx = [idx, [length(stats)+1:K]];
for i = length(idx):-1:1
    k = idx(i);
    stats(k,1).Area = 0;
    stats(k,1).Centroid = default_centroid;
    stats(k,1).BoundingBox = default_bbox;
    if i == 1
        stats(k,1).PixelIdxList = [];
    end
end
end
