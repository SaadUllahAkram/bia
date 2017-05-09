function im = roi(opts, im, foi)
% draws the image border and field of interest rectangle.
% assumes image is 'uint8'
% 
% Inputs:
%     im: image
%     foi: how many pixels at image border are ignored
% 

opts_default = struct('out',[0 255 0],'in',[255 0 0], 'line_w', 1);
opts = bia.utils.updatefields(opts_default, opts);
line_w = opts.line_w;
in = opts.in;% color of inner field of interest (foi) rectangle
out = opts.out;% color of outer rectangle

sz = size(im);

if length(sz) == 2
    im = repmat(im, [1 1 3]);
end

if length(in) == 3 && sum(in) > 0
    im = add_line(im, foi, in, line_w);
end

if length(out) == 3 && sum(out) > 0
    im = add_line(im, 1, out, line_w);
end

end


function im = add_line(im, foi, col, line_w)

assert(rem(line_w, 2) == 1, 'line_width must be odd.')

foi2 = foi-1;
sz = size(im);
h = sz(1)- 2*foi + 2;
w = sz(2)- 2*foi + 2;

if foi <= 1
    o1 = 0;
    o2 = line_w-1;
else
    o1 = (line_w-1)/2;
    o2 = o1;
end

col = permute(col, [1 3 2]);
vert_line = repmat(col, [h line_w]);
horiz_line = repmat(col, [line_w w]);

im(foi:end-foi2, foi-o1:foi+o2, 1:3) = vert_line;
im(foi:end-foi2, end-foi2-o2:end-foi2+o1, 1:3) = vert_line;
im(foi-o1:foi+o2, foi:end-foi2, 1:3) = horiz_line;
im(end-foi2-o2:end-foi2+o1, foi:end-foi2, 1:3) = horiz_line;

end