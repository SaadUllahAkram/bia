function stats = roi_stats(mask, roi, sz, score)
% Computes stats of a region (in orig image) using the ROI
% 
% Inputs:
%     mask: binary mask
%     roi: [ymin ymax xmin xmax] of mask in the orig image
%     sz: size of orig image
%     score: score of the roi
% Outputs:
%     stats:
%

[r,c]   = find(mask);

r       = double(r+roi(1)-1);
c       = double(c+roi(3)-1);
idx_rm  = r < 1 | c < 1 | r > sz(1) | c > sz(2);
r(idx_rm) = [];
c(idx_rm) = [];

px      = sub2ind(sz, r, c);
stats   = bia.stats.pixelidxlist2stats(px, sz);

if nargin == 4
    stats.Score = score;
end
end
