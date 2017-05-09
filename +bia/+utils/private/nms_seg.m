function [stats_nms, pick] = nms_seg(stats, overlap)
% does non-maxima segmentation using segmentation masks
% stats has a "Score" field which is used for NMS
% 
% Inputs:
%     stats.{Area, PixelIdxList, BoundingBox, Score} : score contains the probability
%     overlap : IoU threshold
% Outputs:
%     stats_nms   : stats after nms
%     idx_nms     : idx of regions remaining after nms
%     
%     


score = [stats(:).Score];
% sort descend
[~, idx] = sort(score, 'descend');

pick    = 0*score;
counter = 1;
iou_bb  = bia.utils.overlap_bb(stats, stats);
while ~isempty(idx)
    i               = idx(1);
    idx(1)          = [];
    pick(counter)   = i;
    counter         = counter + 1;
    
    iou     = zeros(1, length(idx));
    for k = 1:length(idx)
        j       = idx(k);
        if iou_bb(i,j) > 0
            iou(k)  = bia.utils.iou_mex(stats(i).PixelIdxList, stats(j).PixelIdxList);
            %iou(k)  = length(intersect(stats(i).PixelIdxList, stats(j).PixelIdxList))/length(union(stats(i).PixelIdxList, stats(j).PixelIdxList));
        else
            iou(k)  = 0;
        end
    end
    idx = idx(iou <= overlap);
end
pick = pick(1:(counter-1));
stats_nms = stats(pick);

end