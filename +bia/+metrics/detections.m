function [f1a, reca, prea, f1score, precision, recall, tp, fp, fn] = detections(res_st, gt_st, threshold)
% Cell Detect Evaluation Criteris: GT and RES detections (CENTROIDS) are matched using hungarian algorithm. Detections > thresh distance from
% GT are considered FP.
%OUTPUT
%   precision, recall, tp (#true positives), fp(#false positives, fn(#false negatives)
%INPUT
%   x,y,xGT,yGT - column vectors with x and y coordinates of detections and GT dots     
%   weightMap = used to recompute the tolerance threshold to accept detections
%       base on depthMaps
%   threshold = maximum distance between detection and GT dot to be matched.
%   image = (optional) argument to visualize the matches and misses. 

% x   = res(:,2);
% y   = res(:,1);
% 
% xGT = gt(:,2);
% yGT = gt(:,1);
% 
% 
% xGT_ = int32(xGT);
% yGT_ = int32(yGT);
% 
% xGT_(xGT_ < 1) = 1;
% yGT_(yGT_ < 1) = 1;
% 
% depthMap = 1.0./sqrt(weightMap);
% xGT_(xGT_ > size(weightMap,2)) = size(weightMap,2);
% yGT_(yGT_ > size(weightMap,1)) = size(weightMap,1);
% 
% thresh = threshold*depthMap(sub2ind(size(depthMap),yGT_,xGT_));
% 
% dy = repmat(double(yGT), 1, size(y,1))- repmat(double(y)', size(yGT,1), 1);
% dx = repmat(double(xGT), 1, size(x,1))- repmat(double(x)', size(xGT,1), 1);
% dR = sqrt(dx.*dx+dy.*dy);
% dR(dR > repmat(thresh, 1, size(y,1))) = +inf;
% matching = Hungarian(dR);
% 
% fp = numel(x)-sum(matching(:));
% fn = numel(xGT)-sum(matching(:));
% tp = sum(matching(:));

T = length(res_st);

for t=1:T
    gt  = gt_st.detect{t};
    res = bia.convert.centroids(res_st{t});
    res = double(res);
    num_res         = size(res,1);
    num_gt          = size( gt,1);
    if num_res == 0 || num_gt == 0
        num_matched = 0;
    else
        dR              = pdist2(gt, res);
        dR(dR > threshold) = +Inf;
        assignments     = assignDetectionsToTracks(double(dR), threshold);%%todo: use a better cost of non-assignment
        num_matched     = size(assignments, 1);
%         if num_matched < 0.5*num_gt
%             res = res(:,[2 1]);
%             dR              = pdist2(gt, res);
%             dR(dR > threshold) = +Inf;
%             assignments     = assignDetectionsToTracks(double(dR), threshold);%%todo: use a better cost of non-assignment
%             num_matched     = size(assignments, 1);
%         end
    end


    fp(t) = num_res - num_matched;
    fn(t) = num_gt - num_matched;
    tp(t) = num_matched;

    precision(t)   = tp(t) / (tp(t) + fp(t));
    recall(t)      = tp(t) / (tp(t) + fn(t));
    f1score(t)     = 2*recall(t)*precision(t)/(recall(t) + precision(t));
end
tpa = sum(tp);
fpa = sum(fp);
fna = sum(fn);
prea = tpa/(tpa+fpa);
reca = tpa/(tpa+fna);
f1a  = 2*reca*prea/(reca + prea);
if nargin == 7
%     imshow(image); hold on;
%     scatter(y(any(matching)),x(any(matching)),'b','o', 'filled');
%     scatter(y(~any(matching)),x(~any(matching)),'r','o', 'filled');
%     scatter(yGT(any(matching,2)),xGT(any(matching,2)),'b','x');
%     scatter(yGT(~any(matching,2)),xGT(~any(matching,2)),'r','x');
%     hold off;
end
