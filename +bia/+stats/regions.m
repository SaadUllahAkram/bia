function stats = regions(mask, im)
% get common stats from labelled objects/regions.
% Input:
%     mask : 2D/3D labelled image
% Output:
%     stats : 
% 

if nargin == 1
    stats = regionprops(mask, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList');
    return
end

if size(im, 3) > 1
    stats = regionprops(mask, im, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList', 'PixelValues', 'MinIntensity', 'MeanIntensity', 'MaxIntensity');
else
    stats = regionprops(mask, im, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList', 'PixelValues', 'MinIntensity', 'MeanIntensity', 'MaxIntensity', 'Eccentricity', 'Solidity', 'Extent', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter', 'Orientation');
end

end
