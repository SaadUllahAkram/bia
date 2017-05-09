function [ap, max_f1, rec, prec, errors] = seg_ap_iou(opts, seg_res, gt)
% evaluates given proposal bboxes or segmentation masks using overlap of bboxes/masks with GT bboxes/masks criteria.
%     TP: If there is IoU of GT and proposal bbox/mask > threshold
%     FP: If IoU of GT (not matched yet) and proposal bbox/mask < threshold
%
% Inputs:
%     bb_nms : [xmin ymin w h score t]
%     seg_nms : "bb_nms" and "seg_nms" should be in same order
%     gt : ground truth structure
% Outputs:
%     ap : area under the precision-recall curve
%     max_f1 : max f1-score for all recall-precision combinations
%     rec : recall values as proposals are evaluated in the order of their score (descending)
%     prec : precision values corresponding to recall values
%

opts_default    = struct('area_thresh',0.5,'verbose',0);
opts            = bia.utils.updatefields(opts_default, opts);

area_thresh     = opts.area_thresh;
verbose         = opts.verbose;

[ap, max_f1, rec, prec, errors] = overlap_bboxes(seg_res, gt, area_thresh, 2, 0, verbose);
end