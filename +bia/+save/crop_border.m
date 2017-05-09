function im = crop_border(im, border_width, border_rgb_vals)
% removes offwhite/white border around images captured using getframe
% 
% Inputs:
%     im: captured image
%     border_width : padding around border
%     border_rgb_vals : Nx3-> list of rgb colors which are removed from border
% Outputs:
%     im: image after padded (offwhite/white) region is removed
% 

sz = size(im);
ch = size(im, 3);
if ch ~= 3% captured figures always have 3 channels
    return
end

top      = 1;
bottom   = sz(1);
left     = 1;
right    = sz(2);
% orig_corners = [top bottom left right];

% find border color from corners
border_rgb = squeeze([im(1,1,:); im(sz(1),1,:); im(1,sz(2),:); im(end,end,:)]);
border_rgb = unique(border_rgb, 'rows');% typical colors are: [240 240 240; 255 255 255]
if size(border_rgb, 1) > 1% there are multiple colors already at corners, so no border to remove
    return;
end
found = 0;
for i=1:size(border_rgb_vals, 1)
    if bia.utils.ssum(border_rgb_vals(i, :) == border_rgb)
        found = 1;
    end
end
if ~found% border color is not what was expected, maybe it was a rgb image with same color at corners, etc
    return;
end
border_row = permute(repmat(border_rgb, sz(2), 1), [3 1 2]);
border_col = permute(repmat(border_rgb, sz(1), 1), [1 3 2]);
for i=1:sz(1)
    if bia.utils.ssum(im(i,:,:)~=border_row)
        top = i;
        break
    end
end
for i=sz(1):-1:1
    if bia.utils.ssum(im(i,:,:)~=border_row)
        bottom = i;
        break
    end
end


for i=1:sz(2)
    if bia.utils.ssum(im(:,i,:)~=border_col)
        left = i;
        break
    end
end
for i=sz(2):-1:1
    if bia.utils.ssum(im(:,i,:)~=border_col)
        right = i;
        break
    end
end
top     = max(1, top-border_width);
left    = max(1, left-border_width);
bottom  = min(sz(1), bottom+border_width);
right   = min(sz(2), right+border_width);
% final_corners = [top bottom left right];
im      = im(top:bottom, left:right, :);

end