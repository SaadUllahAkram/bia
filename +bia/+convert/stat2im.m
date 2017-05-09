function im = stat2im(stats, sz)
% creates a labeled image (uint16) from given stats.
% 
% Inputs:
%     stats.{Area, PixelIdxList} : stats of objects in the image
%     sz : [w, h, d], size of resulting image
% Outputs:
%     im : labeled image
% 

areas = [stats.Area];
if length(areas) ~= length(stats)
    error('Some Area values are missing')
end

idx = find(areas > 0);
im = zeros(sz, 'uint16');
for k=idx
    im(stats(k).PixelIdxList) = k;
end