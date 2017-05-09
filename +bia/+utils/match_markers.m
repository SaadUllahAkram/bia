function [fn, fn_idx, gt2det, det2gt, gt2det_ious, det2gt_ious, iou_ctc_gt] = match_markers(gt_stats_tra, stats_res)
% Inputs:
%     gt_stats_tra.{Area, PixelIdxList, BoundingBox}
%     stats.{same as gt_stats_tra}
% Outputs:
%     fn        : # Fasle Negatives
%     fn_idx    : idx of GT which are missed (FN).
%     gt2det    : ids of "PROPS" which contain this GT
%     det2gt    : ids of "gt" which are inside PROPS
%

[iou_ctc, ~, iou_ctc_gt] = bia.utils.overlap_pixels(gt_stats_tra, stats_res, 0.5);

% det2gt: ids of "gt" which are inside PROPS
num_res         = length(stats_res);
det2gt          = cell(num_res, 1);
det2gt_ious     = cell(num_res, 1);
for i=1:num_res% get the gt id for each res id
    det2gt{i,1} = find(iou_ctc_gt(:,i));
    det2gt_ious{i,1} = iou_ctc_gt(det2gt{i,1},i);
end

% gt2det: ids of "PROPS" which contain this GT
num_gt          = length(gt_stats_tra);
gt2det          = cell(num_gt, 1);
gt2det_ious     = cell(num_gt, 1);
for i=1:num_gt% get the gt id for each res id
    gt2det{i,1}         = find(iou_ctc_gt(i,:));
    gt2det_ious{i,1}    = iou_ctc_gt(i, gt2det{i,1});
end

iou_ctc_best    = max(iou_ctc,[],2);% best IoU for each GT
area            = [gt_stats_tra(:).Area];
fn_idx          = find(iou_ctc_best == 0 & area' > 0)';
iou_ctc_best(area==0) = [];% remove empty entries in gt_stats struct
fn              = sum(iou_ctc_best==0);
end