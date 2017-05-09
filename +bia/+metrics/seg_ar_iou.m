function [average_recall, recall, area_vals] = seg_ar_iou(opts, seg_res, gt)
% evaluates given proposal bboxes or segmentation masks using overlap of bboxes/masks with GT bboxes/masks criteria.
%     TP: If there is IoU of GT and proposal bbox/mask > threshold
%     FP: If IoU of GT (not matched yet) and proposal bbox/mask < threshold
%
% Inputs:
%     bb_nms : [xmin ymin w h score t]
%     seg_nms : "bb_nms" and "seg_nms" should be in same order
%     gt : ground truth structure
% Outputs:
%     average_precision : area under the precision-recall curve
%     final_f1score : max f1-score for all recall-precision combinations
%     recall : recall values as proposals are evaluated in the order of their score (descending)
%     precision : precision values corresponding to recall values
%

opts_default    = struct('top_x',883,'IoU_areas',0.5:0.05:1,'verbose',0);
opts            = bia.utils.updatefields(opts_default, opts);

area_vals       = opts.IoU_areas;
top_x           = opts.top_x;
verbose         = opts.verbose;

N           = length(area_vals);% # of IoUs at which evaluation is done
recall      = zeros(1,N);

for i = 1:N
    [~,~,rec, ~, errors] = overlap_bboxes(seg_res, gt, area_vals(i), 2, top_x, verbose);
    recall(i) = rec(end);
end
average_recall  = mean(recall);
end