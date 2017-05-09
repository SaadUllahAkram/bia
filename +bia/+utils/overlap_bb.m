function o = overlap_bb(gt, res)
% computes overlap of bounding boxes [2d/3d].
% accepts matrix or struct as input
% 
% Inputs:
%     gt  : either Nx[4|6] matrix or a structure containing 'BoundingBox' field. 
%     res : same as gt
% Outputs:
%     o : [num_gt x num_res] matrix containing IoU overlap value
% 

if nargin == 1
    res = gt;
end
% convert structs to matrix
if isstruct(gt)
    [bb_gt, idx_gt] = bia.convert.bb(gt, 's2m');
elseif isnumeric(gt)
    bb_gt = gt;
    idx_gt = 1:size(bb_gt,1);
end
if isstruct(res)
    [bb_res, idx_res] = bia.convert.bb(res, 's2m');
elseif isnumeric(res)
    bb_res = res;
    idx_res = 1:size(bb_res,1);
end

o = zeros(size(gt, 1), size(res, 1));
if isempty(bb_gt) || isempty(bb_res)
    return;
end

if size(bb_gt, 2) == 4
    dim = 2;
    idx_st = 1:2;
    idx_en = 3:4;
elseif size(bb_gt, 2) == 6
    dim = 3;
    idx_st = 1:3;
    idx_en = 4:6;
end

active_gt = find(sum(bb_gt(:, idx_en), 2))';

area_gt  = bb_gt (:,idx_en(1)) .* bb_gt (:,idx_en(2));
area_res = bb_res(:,idx_en(1)) .* bb_res(:,idx_en(2));
if dim == 3
    area_gt  = area_gt .* bb_gt (:,idx_en(3));
    area_res = area_res.* bb_res(:,idx_en(3));
end

bb_gt (:,idx_en) = bb_gt (:,idx_st) + bb_gt (:,idx_en) - 1;
bb_res(:,idx_en) = bb_res(:,idx_st) + bb_res(:,idx_en) - 1;

for i=active_gt
    bb = bb_gt(i, :);
    area_common = max(0, min(bb_res(:,idx_en(1)), bb(idx_en(1))) - max(bb_res(:,idx_st(1)), bb(idx_st(1))) + 1).* ...
        max(0, min(bb_res(:,idx_en(2)), bb(idx_en(2))) - max(bb_res(:,idx_st(2)), bb(idx_st(2))) + 1); % XY-Overlap
    if dim == 3
        area_common = area_common .* max(0, min(bb_res(:,idx_en(3)), bb(idx_en(3))) - max(bb_res(:,idx_st(3)), bb(idx_st(3))) + 1);
    end
    idx = area_common ~= 0;
    areas_common_sel = area_common(idx);
    areas_res_sel = area_res(idx);

    o(idx_gt(i), idx_res(idx))   = areas_common_sel./(area_gt(i)+areas_res_sel-areas_common_sel);
end
end