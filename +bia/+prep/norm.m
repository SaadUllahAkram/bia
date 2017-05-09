function im_out = norm(im, type, opts)
% normalizes the given image
% 
% Inputs:
%     im: image
%     type: norm type
%         sq :: sqrt
%         mm :: minmax
%         pt :: percentile
%     opts:
% Outputs:
%     im_out: normalized image
% 

if nargin < 2
    type = 'mm';%minmax
end
if nargin < 3
    opts = [];
end
opts_default = struct('class','','percentiles',[0.01 99.99], 'norm', [], 'power', 1);
opts = bia.utils.updatefields(opts_default, opts);

power = opts.power;
class = opts.class;% class of the output image
norm = opts.norm;
perc = opts.percentiles;
if strcmp(type, 'sq') || strcmp(type, 'sqrt')
    im_out = minmax(sqrt(single(im)));
    class = 'uint8';
elseif strcmp(type, 'p')
    im_out = minmax(single(im).^power);
    class = 'uint8';
elseif strcmp(type, 'mm') || strcmp(type, 'minmax')
    im_out = minmax(im);
elseif strcmp(type, 'pt') || strcmp(type, 'percentile')
    if isempty(norm)
        im = double(im);
        norm = prctile(im(:), [perc(1) perc(2)]);
    end
    im_out = uint8(255*( double(im) - norm(1) )/(norm(2)-norm(1)));
    class = 'uint8';
end

if strcmp(class, 'uint8') && (isa(im_out, 'single') || isa(im_out, 'double'))
    im_out = uint8(255*im_out);
end

end


function im_out = minmax(im)
if isa(im, 'uint8') || isa(im, 'uint16')  || isa(im, 'logical')
    im = single(im);
    newMax = 255;
    cs = 'uint8';
elseif isa(im, 'double') || isa(im, 'single')
    newMax = 1;
    cs = class(im);
end
minValue = min(im(:));
maxValue = max(im(:));

im_out = cast(newMax*((im-minValue)/(maxValue - minValue)), cs);
end