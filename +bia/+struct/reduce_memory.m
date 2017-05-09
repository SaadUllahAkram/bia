function [stats, idx_kept] = reduce_memory(mode, stats, idx_kept)
% 1-> transforms stats to reduces memory usage
% 2-> transforms stats back
% 
% 
% [stats_small, idx_kept] = bia.struct.reduce_memory(1, STATS_TRA_3D);
% [stats_big, idx_kept]   = bia.struct.reduce_memory(2, stats_small, idx_kept);
% assert(isequaln(STATS_TRA_3D, stats_big), 'Both array/structs are not exactly same');
% 

if mode == 2
    assert(nargin == 3)
end

if iscell(stats)
    if mode == 1
        for t=1:length(stats)
            [stats{t}, idx_kept{t}] = bia.struct.standardize(stats{t},'seg');
            if size(stats{t},2) > size(stats{t},1)
                stats{t} = stats{t}';
            end
        end
    elseif mode == 2
        max_n = 0;
        for t=1:length(stats)
            max_n = max(max_n, max(idx_kept{t}));
        end
        for t=1:length(stats)
            stats{t} = stats_expand(stats{t}, idx_kept{t}, max_n);
            if size(stats{t},2) > size(stats{t},1)
                stats{t} = stats{t}';
            end
        end
    end
else
    if mode == 1
        [stats, idx_kept] = bia.struct.standardize(stats,'seg');
    elseif mode == 2
        max_n = max(idx_kept);
        stats = stats_expand(stats, idx_kept, max_n);
    end
end
end

function stats2 = stats_expand(stats, idx, max_n)
% max_n is needed as in case of cell array it is not clear what is the overall max value (length of stats)
    dim         = length(stats(1).Centroid);
    stats2(idx) = stats;
    for i=1:max_n
        if length(stats2)<i
            stats2(i).Area = [];
        end
        if isempty(stats2(i).Area)
            stats2(i).Area          = 0;
            stats2(i).PixelIdxList  = [];
            if dim == 2
                stats2(i).BoundingBox = [0.5 0.5 0 0];
                stats2(i).Centroid    = [NaN NaN];
            elseif dim == 3
                stats2(i).BoundingBox = [0.5 0.5 0.5 0 0 0];
                stats2(i).Centroid    = [NaN NaN NaN];
            end
        end
    end
end
