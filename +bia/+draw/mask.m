function im = mask(opts, im, mask)
% creates a blended image, mixing image intensity and colored image (representing cell id)
% 
% Inputs:
%     opts:
%     im: image
%     mask: labeled image OR stats of regions
% Outputs:
%     im: image with pixels colored
% 

opts_default = struct('cmap','prism','alpha',1,'ratio',0.5);
opts = bia.utils.updatefields(opts_default, opts);

cmap = opts.cmap;
alpha = opts.alpha;
ratio = opts.ratio;% [0-1] contribution of orig image intensity in final blended image
if length(size(im)) == 2
    im = repmat(im, 1, 1, 3);
end

if isstruct(mask)
    stats = mask;
else
    stats = regionprops(mask, 'Area', 'PixelIdxList');
end

colors = (1-ratio)*alpha*255*bia.utils.colors(cmap, length(stats));
N = numel(mask);

idx_active = find([stats(:).Area]>0);
for i=idx_active(:)'
    idx         = stats(i).PixelIdxList;
    im(idx)     = ratio*im(idx) + colors(i, 1);
    im(idx+N)   = ratio*im(idx+N) + colors(i, 2);
    im(idx+N*2) = ratio*im(idx+N*2) + colors(i, 3);
end
end