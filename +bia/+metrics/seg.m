function [seg, seg_f, errors] = seg(opts, res_stats, gt)
% seg: based on Jaccard similarity index
% evaluates cpn's segmentation using Cell Tracking Challeneg Criteria. IoU
% 
% Inputs:
%     opts: settings
%     res_stats: structure containing the stats of segmentations
%     gt.{sz, seg.stats, seg.info}: GT structure
% Outputs:
%     seg     : seg Score, ISBI Challenege Criteria
%     seg_f   : seg Score for only fully segmented frames
%

if isempty(gt) || ~isfield(gt, 'seg') || (isfield(gt, 'seg') && isempty(gt.seg.info))
    seg = -1;
    seg_f = -1;
    errors = struct('fp', 0, 'fn', 0);
    return
end
opts_default    = struct('sz_res', gt.sz, 'proposals', 0, 'warn', 1);
opts            = bia.utils.updatefields(opts_default, opts);

proposals       = opts.proposals;
sz_res          = opts.sz_res; % size of images used for segmentation
sz_gt           = gt.sz;% GT image size
gt_seg_info     = gt.seg.info;
warn            = opts.warn;

T               = length(res_stats);
stats_res       = cell(T,1);

for t=1:T
    if gt_seg_info(t,2) == 0
        continue
    end
    stats_res{t} = res_stats{t};
    % sort regions by their score
    if isfield(stats_res{t}, 'Score')
        idx_valid   = find([stats_res{t}(:).Area]>0);
        scores      = [stats_res{t}(idx_valid).Score];
        [~, idx]    = sort(scores, 'descend');
        stats_res{t}= stats_res{t}(idx_valid(idx));
    elseif t== 1 && proposals == 1
        if warn;    warning('Score field missing, in case of multiple labels for a pixel, final label is not the one with highest score');  end
    end
    
    % ensure that no pixel has multiple labels
    if proposals == 0
        imr         = bia.convert.stat2im(stats_res{t},sz_res(t,:));
        stats_res{t}= regionprops(imr,'Area','BoundingBox','PixelIdxList');
    end
    
    % resize results to GT size
    if ~isequal(sz_res(t,:), sz_gt(t,:))
        warning('Resizing may interfere with proposals by assigning 1 label to each pixel')
        imr = imresize(bia.convert.stat2im(stats_res{t},sz_res(t,:)),sz_gt(t,:),'nearest');
        stats_res{t}=regionprops(imr,'Area','PixelIdxList','BoundingBox');
    end
    stats_res{t}=bia.struct.standardize(stats_res{t},'seg');
end
[seg, seg_f, errors] = compute_seg(stats_res,gt);
% SEG1 = evaluate_ct3(stats_res,0,'seg',seq_name,gt);
% fprintf('****************CTC:FULL -> %1.3f: %1.3f****************\n', SEG1, seg)
end

function [seg, seg_f, errors] = compute_seg(res_stats, gt)
% computes seg measure given gt and result stats
gt_stats    = gt.seg.stats;
gt_seg_info = gt.seg.info;

ious_all        = [];% ious values for all masks
ious_fully_seg  = [];% iou values for masks in fully segmented frames only
fn = cell(gt.T,1);
fp = cell(gt.T,1);
for t = 1:gt.T % N -> # of Slices with GT seg mask
    gt_stats_t = gt_stats{t};
    if sum([gt_stats_t.Area] > 0) == 0
        continue
    end
    res_stat_t  = res_stats{t}; %todo: for 3D case, select the appropriate slice, reconstruct the 3D stack and select the correct slice
    if isempty(res_stat_t)
        ious        = zeros(1, length(gt_stats_t));
        ious_res    = zeros(1, length(res_stat_t));
    else
        ious        = bia.utils.overlap_pixels(gt_stats_t, res_stat_t, 0.5);
        ious_res    = max(ious, [], 1)';% best iou for each GT
        ious        = max(ious, [], 2)';% best iou for each GT
    end
    activeGT    = find([ gt_stats_t.Area ] > 0);
    active_res  = find([ res_stat_t.Area ] > 0);
    ious_all    = [ious_all, ious(activeGT)];
    fn{t,1} = find(ious(activeGT) < 0.5);
    fp{t,1} = find(ious_res(active_res) < 0.5);

    if gt_seg_info(t, 3) == 1
        ious_fully_seg = [ious_fully_seg, ious(activeGT)];
    end
end
errors  = struct('fp', fp, 'fn', fn);
seg     = mean(round(ious_all, 6));
seg_f   = mean(round(ious_fully_seg, 6));
end