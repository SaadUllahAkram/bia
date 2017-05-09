function bw = bernsen_threshold(opts, im)
% binary segmentation using bernsen's thresholding
% 
% Inputs:
%     opts:
%     im: grayscale image
% Outputs:
%     bw: binary segmented image
%     

opts_default = struct('win',29,'contrast_thresh',30,'use_sqrt',0,'min_size',0,'opening',0);
opts = bia.utils.updatefields(opts_default, opts);

% binary seg
min_area        = opts.min_size;
win             = opts.win;% odd value
se_erode        = ones(opts.opening);
se_dilate       = ones(opts.opening);
contrast_thresh = opts.contrast_thresh;

if numel(win) == 1
    win = [win win];
end
w = ceil(win/2);


im_pad = double(padarray(im, w, 'symmetric'));
if opts.use_sqrt
    im_pad = sqrt(im_pad);
end

bw_pad = bernsen(im_pad, win, contrast_thresh);

bw_pad = imerode(bw_pad, se_erode);
bw_pad = bwareaopen(bw_pad, min_area);
bw_pad = imdilate(bw_pad, se_dilate);
bw_pad = imfill(bw_pad, 'holes');


bw = bw_pad(w+1:end-w, w+1:end-w);
end
