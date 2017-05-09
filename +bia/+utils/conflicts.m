function [constraints, conflicts, w] = conflicts(opts, stats)
% takes segmentation proposals and finds which pair of of them conflict with each other.
%
% Inputs:
%     stats.{Area, PixelIdxList, BoundingBox, Centroid} : of proposal regions
% Outputs:
%     stats.{level, branches, parent, child} : stats arranged in tree form
%             adds a new field "level" [1,2, ...] which indicates how far along the tree a proposal is. level=1 -> top most proposal
%             and "branches" which indicates to which branches the proposal belongs
%             and "parent" and "child" fields. Lists immediate parents and daughters. Is (-1) in case of no parent or daughters
%     conflicts : a matric containing "1" in locations where region in row# conflicts with region in col#
%     constraints: each row contains a constraint, which has 1 in columns indicating which props conflict with each other.
%     w :  [not implemented]

opts_default    = struct('conflict_iou', 0.2, 'conflict_int_thresh',0.9,'version',0,'verbose',0);
opts            = bia.utils.updatefields(opts_default, opts);

conflict_iou          = opts.conflict_iou;% max % of pixels of a new props which can be inside an old (already added to the tree) prop.
conflict_int_thresh       = opts.conflict_int_thresh;% overlap threshold (NOT IOU) "int(A,B)/A > threshold" for a node "A" to be a child

N = length(stats);
w = ones(N, 1);
[~,~,int_a,iou] = bia.utils.overlap_pixels(stats, stats, conflict_int_thresh);% int_a: intersection(a,b)/|a|
if conflict_int_thresh == -1
    int_a = false(size(int_a));
else
    int_a = int_a > conflict_int_thresh;
end
if conflict_iou == -1
    iou = false(size(iou));
else
    iou = iou > conflict_iou;
end


conflicts = int_a | iou | int_a' | iou';
% fprintf('%d, %d, %d\n', sum(sum(int_a>0)), sum(sum(iou>0)), sum(sum((iou+int_a) > 0)))

% get ILP constraints
vals = [];
for i=1:size(conflicts,1)
    idx = find(conflicts(i,:));
    idx = setdiff(idx, i);
    for j=1:length(idx)
        vals = [vals; i, idx(j)];
    end
end

constraints = sparse(false(size(vals,1), size(conflicts,1)));
for i=1:size(vals,1)
    constraints(i, vals(i,:)) = true;
end

return