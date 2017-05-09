function [stats, idx_kept] = standardize(stats, type, dim)
% 
% Standardizes struct by filling empty structs and getting rid of unnecessary structs
% 
% Inputs:
%     stats: cell array of stats
%     tracks: 1 (standardize tracks), 0(standardize segmentation stats)
% Outputs:
%     stats: after standardization
%     idx_kept: cell array in case of seg/prop, and array in case of tra
% 
% 
% All structs must have the fields (deafult values): Area (0), BoundingBox(0.5 0.5 0 0), Centroid(NaN NaN), PixelIdxList ([])
% 3 Types of structures: 
%     1. Segmentations
%         no empty struct,
%         no overlap between masks
%     2. Proposals
%         no empty struct
%     3. Tracks
%         no empty struct in all frames
% 
% 1. Fills empty entries of struct
% 2. Ensures the size of stats is same for all tracking frames


if nargin < 3 || isempty(dim)
    dim = 2;
end
if nargin < 2 || isempty(type)
    type = 'tra';
end

stats = bia.struct.fill(stats, '', dim);
% if strcmp(type, 'tra')
% elseif strcmp(type, 'seg')
% elseif strcmp(type, 'prop')
% end
[stats, idx_kept] = compact_stats(stats, type);
end


function [stats, idx_kept] = compact_stats(stats, type)
% removes track ids which are empty, uses "Area" field to decide which tracks are empty
% 
% Inputs:
%     stats: a cell array of tracked object's stats at each 't'

if isstruct(stats)
    num_tra = length(stats);
    idx_rm = find([stats.Area] == 0);
    idx_kept= setdiff(1:num_tra, idx_rm);
    stats(idx_rm) = [];    
else
    T = length(stats);
    for t=1:T
        len = length(stats{t});
        areas(t,1:len) = arrayfun(@(x) stats{t}(x).Area, 1:len);
    end
    num_tra = size(areas, 2);
    if strcmp(type, 'tra')
        idx_rm  = find(sum(areas)==0);
        idx_kept= setdiff(1:num_tra, idx_rm);
    end


    for t=1:T
        n = length(stats{t});
        if ~strcmp(type, 'tra')
            idx_rm  = areas(t,:)==0;
            idx_kept{t,1}= setdiff(1:n, idx_rm);
        end
        idx_rm_t = idx_rm;
        idx_rm_t(idx_rm_t > n) = [];
        stats{t}(idx_rm_t) = [];
    end
end

end