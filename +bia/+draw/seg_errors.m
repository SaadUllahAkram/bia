function [mask_rgb, fused, res] = seg_errors(im, mask_seg, mask_gt, handles)
% displays segmentation such that:
%  mask_seg > 0 && mask_gt > 0 --> TP --> White
%  mask_seg== 0 && mask_gt ==0 --> TN --> Black
%  mask_seg== 0 && mask_gt > 0 --> FN --> Red
%  mask_seg > 0 && mask_gt ==0 --> FP --> Green

% Only displays the image if no fusedput is taken from this function

if nargin < 4 && ~nargout
    figure;
    handles(1) = subplot(1,2,1);
    handles(2) = subplot(1,2,2);
elseif nargin == 4
    assert(length(handles) == 2, 'Expected handles to be in a struct array of length 2')
end
mask_gt     = uint8(mask_gt);
mask_seg    = uint8(mask_seg);

mask_rgb    = zeros([size(mask_gt), 3], 'uint8');
mask_tp     = mask_seg>0 & mask_gt >0;
mask_rgb    = set_color(mask_rgb, mask_tp, [255 255 255]);
mask_tn     = mask_seg==0 & mask_gt ==0;
mask_fn     = mask_seg==0 & mask_gt >0;
mask_rgb    = set_color(mask_rgb, mask_fn, [255 0 0]);
mask_fp     = mask_seg>0 & mask_gt ==0;
mask_rgb    = set_color(mask_rgb, mask_fp, [0 255 0]);

idx_fp      = find(mask_fp);
idx_fn      = find(mask_fn);
idx_tp      = find(mask_tp);
idx_tn      = find(mask_tn);
res         = struct('fp',length(idx_fp),'fn',length(idx_fn),'tp',length(idx_tp),'tn',length(idx_tn));
fused       = fuse_seg_res(struct('brighten',1), im, idx_fp, idx_fn);

if ~nargout
    imshow(im, 'parent', handles(1))
    imshow(mask_rgb, 'parent', handles(2))
end
end

function fused = fuse_seg_res(opts, im, fp, fn)
fused   = repmat(im, [1 1 3*(size(im,3)==1)+1*(size(im,3)==3)]);
n       = size(im,1)*size(im,2);
m       = max(fused(:));

fused([n+fn; 2*n+fn]) = 0;% retain red component only
fused([fp;   2*n+fp]) = 0;%retain green component only
fused(fn)   = opts.brighten*fused(fn);
fused(fp)   = opts.brighten*fused(fp);

fused(fused > m) = m;
end

function color_im = set_color(color_im, mask, col)
assert(length(col)==3)

sz = size(mask);

[r, c]  = find(mask);
idx     = sub2ind(sz, r, c);
color_im(idx)               = col(1);
color_im(idx+prod(sz))      = col(2);
color_im(idx+prod(sz)*2)    = col(3);
end
