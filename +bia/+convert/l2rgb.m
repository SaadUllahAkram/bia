function im_rgb = l2rgb(im, Flag)
% todoIN:
%     x. change coloring method (if can find anything better than 'lines')
% Inputs:
%     im : 2D/3D labeled image
% Outputs:    
%     im_rgb (HxWx3xZ) :  labels are converted to color

if nargin < 2
    Flag = 0;
end

Z = size(im,3);
im_rgb = zeros(size(im,1), size(im,2), 3, size(im,3), 'uint8');
cmap = bia.utils.colors('', max(im(:)));
if Z == 1
    im_rgb = label2rgb(im,cmap,'k');
else
    for z=1:Z
        im_rgb(:,:,:,z) = label2rgb(im(:,:,z),cmap,'k');
    end
end

if Flag == 1
    montage(im_rgb)
end
