function [im, props] = ws(path,level)
% reads the whole slide images of histological samples in windows.
% 
% Requires openslide_matlab: https://github.com/fordanic/openslide-matlab
% 
% Inputs:
%     path : full path of whole slide image
%     level: level which should be read. 0-> most detailed
% Outputs:
%     im : read image
%     props : properties of whole slide
%

slide_ptr = openslide_open(path);
[x_res,y_res,width,height,num_levels,downsample_factors,objective] = openslide_get_slide_properties(slide_ptr);

props = struct('width', width, 'height', height, 'num_levels', num_levels, 'scalings', downsample_factors, 'objective',objective, 'x_res', x_res, 'y_res', y_res, 'size', (width*height)/1024/1024/1024);
if level >= num_levels
   level = num_levels-1;
end
w1= 0;
h1= 0;
w = width;
h = height;
if level~=0
   w = round(w/downsample_factors(level+1));
   h = round(h/downsample_factors(level+1));
end
im = openslide_read_region(slide_ptr,w1,h1,w,h,'level',level);
tmp = im(:,:,1);
% assert(length(unique(tmp)) == 1)
% assert( unique(tmp) == 255)
% assert( min(tmp(:)) == 200)

im = im(:,:,2:4);
props.settings.level_sel = level;
end
