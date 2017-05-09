function im = getframe(h, cols)
% grabs frame and crops it by removing border pixels

% Inputs:
%     h: figure handle
%     cols: Nx3 color matrix used to remove homogeneous image border region
% Outputs:
%     im: captured image
%     

border_width    = 0;% padding around image border
border_rgb_vals = uint8([240, 240, 240]);

if nargin == 0
    h = gcf;
end

im = frame2im(getframe(h));
im = bia.save.crop_border(im, border_width, border_rgb_vals);
if nargin > 1
    for i=1:size(cols, 1)
        im = bia.save.crop_border(im, border_width, cols(i,:));
    end
end
end
