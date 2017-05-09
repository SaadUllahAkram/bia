function layer = roi_pool(name, bottom, rois, pooled_sz, spatial_scale)
% ROIPooling layers takes bbox in format [id top_left_corner(x,y) bottom_right_corner(x,y)]

% bottom: name of layer containing feature maps
% rois: name of layer containing rois
if length(pooled_sz) == 1
    pooled_sz = [pooled_sz, pooled_sz];
end

layer = struct('name',name,'type','ROIPooling','bottom',{{bottom,rois}},'top',name,...
    'roi_pooling_param',struct('pooled_w',pooled_sz(1), 'pooled_h',pooled_sz(2),'spatial_scale',spatial_scale));
end