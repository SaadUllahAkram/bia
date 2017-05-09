function matched = match(opts, gt, res, sz)
% 
% Matches result and GT
% 
% Match types:
% p: use centroids
%     only 1 inside
%     any inside
% ctc: use markers inside a region
%     CTC, in > 0.5
% seg: use mask overlaps
%     IoU > Thresh
% 

opts_default = struct('use','ctc','max_match',1);
opts = bia.utils.updatefields(opts_default, opts);

use = opts.use;% 1. ctc: use ctc criteria (intersect(A,B)/|B| > 0.5), 2. p: use centroid location, 3. seg: use IoU(A,B)>thresh
max_match = opts.max_match;% if a res matches more than this many gt, set all its matches to '0' (unmatch them)

n = length(gt);
m = length(res);
matched = zeros(n,m);

if strcmp(use, 'p')% match(i,j)=1, if i-th gt centroid is inside j-th res
    [gt_cents, idx] = bia.convert.centroids(gt);
    gt_cents_idx = sub2ind(sz, gt_cents(:,2), gt_cents(:,1));
    for k=1:length(idx)
        i = idx(k);
        for j=1:m
            matched(i,j) = bia.utils.iou_mex(gt_cents_idx(k), res(j).PixelIdxList) > 0;%parfor is slower
        end
    end
elseif strcmp(use, 'ctc')% use ctc criteria
    matched = bia.utils.overlap_pixels(gt, res, 0.5);
    matched = double(matched>0);
end

if max_match >= 1% if a res matched with 1+ gt, set those entries to 0
    for i=1:size(matched,2)
        if sum(matched(:,i)) > max_match
            matched(:,i) = 0;
        end
    end
end

end