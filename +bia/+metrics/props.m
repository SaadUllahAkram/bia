function fn = props(gt, res, verbose)
% evaluates given proposals
% 
% Inputs:
%     gt: ground truth
%     res: struct of proposals
% 

if nargin < 3
    verbose = 0;
end

if iscell(res)
    T = length(res);
    fn = zeros(1, T);
    tp = zeros(1, T);
    n_gt = zeros(1, T);
    n_props = zeros(1, T);
    for t=1:T
        [fnt, tpt, n_gtt, n_propst] = eval_props_local(gt.tra.stats{t}, res{t}, verbose);
        fn(t) = fnt;
        tp(t) = tpt;
        n_gt(t) = n_gtt;
        n_props(t) = n_propst;
    end
else
    [fn, tp, n_gt, n_props] = eval_props_local(gt, res, verbose);
end

if verbose
    fprintf('#GT: %d, #Proposals: %d, strict-FN: %d, TP:%d\n', sum(n_gt), sum(n_props), sum(fn), sum(tp))
end
end


function [fn, tp, n_gt, n_props] = eval_props_local(gt_stats, res, verbose)
% take stats from gt
gt_active = find([gt_stats(:).Area]> 0);
n_gt = length(gt_active);
n_props = length(res);
[iou, matches] = bia.utils.overlap_pixels(gt_stats, res, 0.5);
fn = length(gt_active) - sum(matches > 0);% strict fn: gt objects outside all proposals
% find how many markers each props contains, if a prop contains only 1 gt, remove that gt.

tp = 0;% gt markers which are inside a proposal which contains only 1 marker.
for i = gt_active
    idx = find(iou(i, :) > 0);
    if ~isempty(idx)
        for j=idx
            if sum(iou(:, j) > 0) == 1
                tp=tp+1;
                break;
            end
        end
    end
end
if verbose
    fprintf('#GT: %d, #Proposals: %d, strict-FN: %d, TP:%d\n', n_gt, n_props, fn, tp)
end
end