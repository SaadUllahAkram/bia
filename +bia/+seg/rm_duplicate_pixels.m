function stats = rm_duplicate_pixels(stats, sz)
% removes duplicate labels for pixels in the region stats
% 
% Inputs:
%     stats :  region stats
%     sz : image size
% 

T = length(stats);
parfor t=1:T
    stats{t} = rm_duplicates(stats{t}, sz(t,:));
end
end


function stats = rm_duplicates(stats, sz)
stats_orig = stats;
im = bia.convert.stat2im(stats, sz);
stats = regionprops(im, 'Area', 'Boundingbox', 'Centroid', 'PixelIdxList');
if isfield(stats_orig(1), 'Score')
    for i=1:length(stats)
        if stats(i).Area > 0
            stats(i).Score = stats_orig(i).Score;
        elseif stats(i).Area == 0
            stats(i).Score = [];%-1;
        end
    end
end
end