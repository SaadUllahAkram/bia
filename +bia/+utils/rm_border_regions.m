function [stats, idx] = rm_border_regions(stats, sz, foi)
% returns regions which are inside the field of interest (i.e. deletes regions in the narrow band around image border)
% 
% Inputs:
%     stats: region stats
%     sz: image size
%     foi : field of interest border thickness
% Outputs:
%     stats: stats of retained regions
%     idx : indices of retained regions
% 

if foi <= 0
   idx = 1:length(stats);
   return
end

[bb, idx_bb] = bia.convert.bb(stats, 's2m');
rm_idx = find(bb(:,1) > sz(2)-foi | bb(:,2) > sz(1)-foi | bb(:,1)+bb(:,3) <= foi | bb(:,2)+bb(:,4) <= foi)';
keep_idx = find(bb(:,1) > foi & bb(:,1) <= sz(2)-foi & bb(:,2) > foi & bb(:,2) <= sz(1)-foi)';

idx_verify = 1:size(bb,1);
idx_verify = setdiff(idx_verify, keep_idx);
idx_verify = setdiff(idx_verify, rm_idx);
idx_verify = idx_bb(idx_verify);
rm_idx_px = px_rm(stats, idx_verify, sz, foi);
rm_idx = [idx_bb(rm_idx)', rm_idx_px];

if ~isempty(rm_idx)
    for i = rm_idx
       stats(i).Area = 0;
       stats(i).Centroid = [NaN NaN];
       stats(i).BoundingBox = [.5 .5 0 0];
       stats(i).PixelIdxList = [];
    end
end
idx = setdiff(1:length(stats), rm_idx);

end


function rm = px_rm(stats, idx, sz, foi)
% some regions outside the foi may have their boxes inside foi. it removes these regions
rm = [];
if isempty(idx)
    return
end
im = zeros(sz);
im(1:foi,:) = 1;
im(:,1:foi) = 1;
im(:,end-foi+1:end) = 1;
im(end-foi+1:end,:) = 1;
st = regionprops(im, 'PixelIdxList');

for i=1:length(idx)
    [~,~,in] = bia.utils.iou_mex(st.PixelIdxList, stats(idx(i)).PixelIdxList);
    if in == stats(idx(i)).Area
        rm = [rm, idx(i)];
    end
end
end