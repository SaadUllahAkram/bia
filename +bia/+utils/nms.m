function [res, picked] = nms(opts,stats)
% does non-maxima suppression using segmentation masks or bounding boxes in 1-4D
% stats.Score or last column of the matrix contains the score of a region
% opts.{use_seg, score, iou}
% 
% Inputs:
%     opts:
%     stats.
%         {Area, PixelIdxList, BoundingBox, Score} : score contains the probability
%  OR
%     stats: matrix: Nx(3 or 5 or 7 or 9), with last column containing the scores.
% Outputs:
%     stats_nms   : stats after nms
%     idx_nms     : idx of regions remaining after nms
%     

opts_default    = struct('iou',0.5, 'score',[], 'use_seg',1);
opts            = bia.utils.updatefields(opts_default, opts);

iou             = opts.iou;% iou threshold
score           = opts.score;% score threshold: []-> use all regions
use_seg         = opts.use_seg;% 1(use seg masks), else (use boxes)

if isstruct(stats)
    if ~isfield(stats, 'Score')
        error('Set "Score" field')
    end
    if ~isfield(stats, 'PixelIdxList')
       use_seg  = 0;
       warning('Segmentation masks not available: using bounding boxes for nms')
       [boxes, idx] = bia.convert.bb(stats, 's2m');
       scores = [stats(idx).Score]';
    else
       scores = [stats(:).Score]';
       idx = [1:length(scores)]';
    end
else
    boxes = stats;
    scores = boxes(:,end);
    idx = [1:length(scores)]';
end

%% remove lower scored regions
if ~isempty(score)
    valid_score = scores > score;% props to be used in nms
    idx = idx(valid_score);
    if use_seg
        stats = stats(valid_score,1);
    else
        boxes = boxes(valid_score,:);
    end
    scores = scores(valid_score,1);
end

if use_seg
    [res, pick] = nms_seg(stats, iou);
    picked = idx(pick);% get the orig idx back
else
    pick = nms_nd([boxes, scores], iou);
    picked = idx(pick);% get the orig idx back
    if isstruct(stats)
        res = stats(picked,1);
    else
        res = boxes(pick,:);
    end
end



end