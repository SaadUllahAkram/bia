function orthView = orth(stack, G, resizeRatio, gapValue)
%todoIn :
%     x. Make color of gap optional (black or white)
%     x. Implement getting top/side1/side2 views using a flag
%     x. Implement showing the results (figure)
%     x. Warn when 2D image is passed
% Inputs:
%   G           : gap between views
%   resizeRatio : ratio between resized Z depth and W & H
%   gapValue    : Values assigned to region in-between different orthogonal views
% Outputs:
%     orthView : TopView    G SideView1
%                SideView2  G Empty Region
if nargin < 2;      G = 20;             end
if nargin < 3;      resizeRatio = 0.25; end
if nargin < 4;      gapValue = 0;       end

H = size(stack,1);
W = size(stack,2);
Z = size(stack,3);
if Z==1 % 2D image passed
    orthView = stack;
    
%% if a 4D matrix is passed    
elseif Z==3 && size(stack,4)>1
    disp('4D matrix is passed to getOrthView.m')
    Z = size(stack,4);
    resizeH = ceil(resizeRatio*H/Z);
    resizeW = ceil(resizeRatio*W/Z);
    ZH = Z*resizeH;
    ZW = Z*resizeW;
    if max(stack(:)) > 255
        orthView = gapValue*ones(H+G+ZH, W+G+ZW, 3, 'uint16');
    else
        orthView = gapValue*ones(H+G+ZH, W+G+ZW, 3, 'uint8');
    end

    orthView(1:H,1:W,:) = max(stack,[],4);
    orthView(H+G+1:end,1:W,:) = flipud(imresize(squeeze(max(stack,[],1))',[ZH W 3])); % bottom side view
    orthView(1:H,W+G+1:end,:) = fliplr(imresize(squeeze(max(stack,[],2)),[H ZW 3])); % side side view
else
    resizeH = ceil(resizeRatio*H/Z);
    resizeW = ceil(resizeRatio*W/Z);
    ZH = Z*resizeH;
    ZW = Z*resizeW;
    if max(stack(:)) > 255
        orthView = gapValue*ones(H+G+ZH, W+G+ZW, 'uint16');
    else
        orthView = gapValue*ones(H+G+ZH, W+G+ZW, 'uint8');
    end

    orthView(1:H,1:W) = max(stack,[],3);
    % why used flip ???     
    orthView(H+G+1:end,1:W) = (imresize(squeeze(max(stack,[],1))',[ZH W], 'nearest')); % bottom side view
    orthView(1:H,W+G+1:end) = (imresize(squeeze(max(stack,[],2)) ,[H ZW], 'nearest')); % side side view

%     orthView(H+G+1:end,1:W) = flipud(imresize(squeeze(max(stack,[],1))',[ZH W], 'nearest')); % bottom side view
%     orthView(1:H,W+G+1:end) = fliplr(imresize(squeeze(max(stack,[],2)) ,[H ZW], 'nearest')); % side side view    
end
% imshow(orthView,[])
% subplot(2,2,1);imshow(squeeze(max(stack,[],1))')
% subplot(2,2,2);imshow(squeeze(max(stack,[],2)))
% subplot(2,2,3);imshow(squeeze(max(stack,[],3)))
% subplot(2,2,4);imshow(orthView)
% pause
end
