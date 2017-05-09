function [lab, px_idx] = largest_obj(lab, fill_holes)
% Returns the largest object
% 
% Inputs:
%     lab: labelled image
% Outputs:
%     lab: binary image with only the largest connected component
%     px_idx: pixelidxlist of the kept object
% 

if nargin == 1
    fill_holes = 0;
end
stats = regionprops(lab, 'Area', 'PixelIdxList');

if isempty(stats)
    px_idx = [];
    return
end

[~, idx] = max([stats(:).Area]);
px_idx = stats(idx).PixelIdxList;
lab = zeros(size(lab));
lab(px_idx) = 1;

if fill_holes
    lab = imfill(lab, 'holes');
end

end