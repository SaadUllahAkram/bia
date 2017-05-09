function r = rect(opts, stats)
% returns tight rectangle [y1,y2,x1,x2] for given region stats or bounding boxes
% 
% Inputs:
%     opts:
%     stats: region stats OR region bounding boxes
% Outputs:
%     r : tight rectangle
% 

opts_default = struct('pad', 0, 'sz', [Inf Inf]);
opts = bia.utils.updatefields(opts_default, opts);
pad = opts.pad;
sz = opts.sz;

if isstruct(stats)
    rects = bia.convert.bb(stats,'s2r');
else
    rects = stats;
end

if isempty(rects)
    r = zeros(0,4);
    return
end
r = rects(1,:);
for i=2:size(rects,1)
    r = rect_union(r, rects(i,:));
end

if pad
   r([1,3]) = max(1,r([1,3])-pad);
   r([2,4]) = min(sz,r([2,4])+pad);
end
end


function r = rect_union(r1, r2)
% finds the union of two rects: r:[top_y, bottom_y, left_x, right_x]
% indices are 1-based
% if nargin == 2
%     r3 = [Inf 0 Inf 0];
% end
r([1,3]) = min([r1([1,3]); r2([1,3])]);
r([2,4]) = max([r1([2,4]); r2([2,4])]);
assert(r(1)>0 && r(3)>0)
end