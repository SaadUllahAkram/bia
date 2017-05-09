function [o_p_thresh, jaccard_index, o_p_gt_thresh, o_p, o_p_gt] = overlap_pixels(gt, res, thresh)
% computes pixel overlaps. accepts struct or labelled images
% 
% thresh must be 0, to get symmetric overlapped pixel scores (i.e. no filtering of outputs)
%
% Inputs:
%     gt  : either labelled image or a structure containing 'BoundingBox' and 'PixelIdxList' fields.
%     res : same as gt
%     thresh [0-1], should be '0.5' for CTC evaluation
% Outputs:
%     o_p_thresh : [#gt x #res] matrix containing pixel overlap value [jaccard index] if "intersect(gt,res) > thresh*|gt|"
%     jaccard_index : highest overlap for each gt object [same as CTC when 'thres == 0.5']
%     o_p_gt_thresh: [#gt x #res] matrix containing "intersect(gt, res) / |gt|" if "intersect(gt,res) > thresh*|gt|"
%     o_p: [#gt x #res] matrix containing pixel overlap value [jaccard index]
%     o_p_gt: [#gt x #res] matrix containing "intersect(gt, res) / |gt|"
%

if nargin < 3
    thresh = 0;
end

% get bbox overlap to speed up processing
if isnumeric(gt) && isnumeric(res)
    gt  = regionprops(gt , 'Area', 'BoundingBox', 'PixelIdxList');
    res = regionprops(res, 'Area', 'BoundingBox', 'PixelIdxList');
end
o_bb = bia.utils.overlap_bb(gt, res);
o_p  = zeros(size(o_bb));% pixel overlap values
o_p_thresh  = zeros(size(o_bb));% pixel overlap values, when "int(gt,res) > thresh*|gt|"
o_p_gt  = zeros(size(o_bb));% int(gt,res)/|gt| values
o_p_gt_thresh = zeros(size(o_bb));% int(gt,res)/|gt| values, when "int(gt,res) > thresh*|gt|"

use_par = 1;
if use_par
    active_gt   = find(sum(o_bb, 2))';
    jaccard_index = zeros(1, size(o_bb, 1));
    area_res    = [res.Area];
    for i = active_gt
        active_res  = find(o_bb(i,:) > 0);
        
        pixel_idx_gt= gt(i).PixelIdxList;
        area_gt_i   = length(pixel_idx_gt);
        
        o_p_thresh_loc      = zeros(1,length(active_res));
        o_p_gt_thresh_loc     = zeros(1,length(active_res));
        o_p_loc      = zeros(1,length(active_res));
        o_p_gt_loc     = zeros(1,length(active_res));
                        
        res_loc     = res(active_res);
        area_res_loc= area_res(active_res);
        if length(active_res) > 100
            parfor k = 1:length(active_res)% for each id of objects in results
                [~,~,area_common_k(k)] = bia.utils.iou_mex(pixel_idx_gt, res_loc(k).PixelIdxList);
            end
        else
            for k = 1:length(active_res)% for each id of objects in results
                [~,~,area_common_k(k)] = bia.utils.iou_mex(pixel_idx_gt, res_loc(k).PixelIdxList);
            end
        end
        for k = 1:length(active_res)% for each id of objects in results
            area_common = area_common_k(k);
            o_p_loc(k) = area_common/(area_gt_i + area_res_loc(k) - area_common);
            o_p_gt_loc(k) = area_common/area_gt_i;
            if area_common > thresh*area_gt_i
                o_p_thresh_loc(k) = o_p_loc(k);
                o_p_gt_thresh_loc(k) = o_p_gt_loc(k);
            end
        end
        o_p(i,active_res) = o_p_loc;
        o_p_gt(i,active_res) = o_p_gt_loc;
        o_p_thresh(i,active_res) = o_p_thresh_loc;
        o_p_gt_thresh(i,active_res) = o_p_gt_thresh_loc;
        
        jaccard_index(i) = max(o_p_thresh(i, :));
    end
else
    active_gt   = find(sum(o_bb, 2))';
    area_gt     = [gt.Area];
    area_res    = [res.Area];
    jaccard_index = zeros(1, size(o_bb, 1));
    for i = active_gt
        active_res  = find(o_bb(i,:) > 0);
        for j = active_res % ids of objects in results
            [~,area_common] = bia.utils.iou_mex(gt(i).PixelIdxList, res(j).PixelIdxList);
            o_p(i, j) = area_common/(area_gt(i) + area_res(j) - area_common);
            o_p_gt(i, j) = area_common/area_gt(i);
            if area_common > thresh*area_gt(i)
                o_p_thresh(i, j) = o_p(i, j);
                o_p_gt_thresh(i, j) = o_p_gt(i, j);
            end
        end
        jaccard_index(i) = max(o_p_thresh(i, :));
    end
end
end
% area_common = sum(ismember(gt.PixelIdxList, res.PixelIdxList));% 3-5x faster than using intersect