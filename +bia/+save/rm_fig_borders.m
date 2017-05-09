function rm_fig_borders(root, border_width)
% removes offwhite /white border around images, saved from matlab figures in the folder provided
% 
% Inputs:
%     root          : full path of dir containing images
%     border_width  : how many border pixels to retain
%

border_rgb_vals = uint8([240, 240, 240; 255, 255, 255]);
if nargin < 2
    border_width = 2;
end

ext = {'*.png', '*.jpg', '*.jpeg'};

if sum(strcmp(root(end), {'/','\'}))
    root = [root, filesep];
end

% get file list
n = length(ext);
list = cell(n,1);
for i=1:n
    list{i} = dir([root, ext{i}]);
end
list = cell2mat(list);

for k=1:length(list)
    file_name = fullfile(root, list(k).name);
    
    im = imread(file_name);
    sz = size(im);
    im = bia.save.crop_border(im, border_width, border_rgb_vals);
    
    if ~isequal(size(im), sz)
        imwrite(im, file_name)
    end
end

end