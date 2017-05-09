function im_c = crop(im, b, type, always_cell)
% extracts the provided ROIs from given image
% 
% Inputs:
%     im: 
%     b: bounding boxes, can be stats OR numeric
%     type: bounding box format, can be 'r' or 'm'
%     always_cell: output must be cell array
% Outputs:
%     im_c: cell array if more than 1 ROI's are extracted OR a numeric image if only 1 ROI is extracted
% 

if nargin < 4
    always_cell = 0;
end
bb_str = 'm2r';
if isstruct(b)
    bb_str(1) = 's';
elseif nargin == 3 && ischar(type)
    bb_str(1) = type;
end

b = bia.convert.bb(b, bb_str);
n = size(b,1);
if n == 1 && always_cell == 0
    im_c = im(b(1):b(2), b(3):b(4), :);
else
    im_c = cell(n,1);
    for i=1:n
        im_c{i} = im(b(i,1):b(i,2), b(i,3):b(i,4), :);
    end
end

end