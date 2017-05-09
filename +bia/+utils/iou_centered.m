function iou = iou_centered(s1, s2, sz, im1, im2)
% computes iou of objects after centering them.
% 
db_show = 0;
if nargin < 4
    db_show = 0;
end
    
dx      = round(s2.Centroid(1)-s1.Centroid(1));
dy      = round(s2.Centroid(2)-s1.Centroid(2));
[y, x]  = ind2sub(sz, s1.PixelIdxList);
y       = y+dy;
x       = x+dx;
% remove pixels outside image border
rm      = y>sz(1) | y<1 | x>sz(2) | x<1;
x(rm)   = [];
y(rm)   = [];

p_after = sz(1)*(x-1) + y;% exactly same as 'sub2ind' for 2d images, used only for speedup

% if sum(p_after == sort(p_after)) ~= length(p_after)
%    warning('Not in order') 
% end
iou     = bia.utils.iou_mex(p_after, s2.PixelIdxList);

% assert(iou >= iou_b)% iou after alligning centers can be lower (nnot often but happens) even in the cases of good match
if db_show
    iou_b   = bia.utils.iou_mex(s1.PixelIdxList, s2.PixelIdxList);
    
    r_pos_neg = bia.convert.rect(bia.convert.bb([s1.BoundingBox; s2.BoundingBox],'m2r'));
    [px1, sz_extract1] = pixelidx_transform(s1.PixelIdxList, size(im1), rect2bb(r_pos_neg));
    [px2, sz_extract] = pixelidx_transform(s2.PixelIdxList, size(im1), rect2bb(r_pos_neg));
    
    im0 = im1;
    im3 = im2;
    
    
    subplot(1,3,1)
    im1 = rect_im(im1, r_pos_neg);
    mask = zeros(sz_extract);
    mask(px1) = 1;
    im1    = bia.draw.boundary([], im1, mask);
    is(im1);
    subplot(1,3,2)    
    im2 = rect_im(im2, r_pos_neg);
    mask = zeros(sz_extract);
    mask(px2) = 1;
    im2    = bia.draw.boundary(struct(), im2, mask);
    is(im2);
    
    subplot(1,3,3)    
    im3 = rect_im(im3, r_pos_neg);
    mask = zeros(sz_extract);
    [px3, sz_extract] = pixelidx_transform(p_after, size(im0), rect2bb(r_pos_neg));
%     mask(px1)       = 1;
%     mask(px2)       = 2;
    mask(px3)       = 3;
    im3             = bia.draw.boundary(struct(), im3, mask);
    is(im3);    
    a=1;title(sprintf('%1.3f->%1.3f', iou_b, iou))
    drawnow
end
% 1. compute difference in centroids
% 2. convert pxidx to [r, c], add offset
% 3. convert back to pxidx
% 4. compute iou
end
