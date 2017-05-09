function im2 = replace_color(im, col1, col2)
% replace col1 with col2 in the given rgb image 
% 
% Inputs:
%     im: RGB image
%     col1: rgb color which has to be replaced
%     col2: new rgb color
%     

im_1 = im(:,:,1);
im_2 = im(:,:,2);
im_3 = im(:,:,3);
idx = im_1 == col1(1) & im_2 == col1(2) & im_3 == col1(3);
im_1(idx) = col2(1);
im_2(idx) = col2(2);
im_3(idx) = col2(3);
im2 = cat(3, im_1, im_2, im_3);

