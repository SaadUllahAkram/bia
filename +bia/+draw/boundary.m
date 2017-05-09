function im = boundary(opts, im, mask)
% draws boundaries of region masks given a labeled image OR stats of regions
% 
% todo: rename to boundary
% 
% Inputs:
%     opts:
%     im: uint8 image [0-255]
%     mask: labelled image OR a struct of region stats
% 
% todo: for struct stats, use tight+border_thickness rect to creating individual region boundaries to speed up

opts_default        = struct('cmap','lines','border_thickness',1,'alpha',0.5,'sort','','fun_boundary',@boundarymask);
opts                = bia.utils.updatefields(opts_default, opts);

border_thickness    = opts.border_thickness;
cmap                = opts.cmap;
alpha               = opts.alpha;
fun_boundary        = opts.fun_boundary;% 1:bwperim (thinner and may have holes) 2: boundarymask (thick)
sort_by             = opts.sort;% '': no sorting, 'area': sort by descending area

if length(size(im)) == 2
    im = repmat(im, 1, 1, 3);
end
sz = [size(im,1), size(im,2)];

if isstruct(mask)% draws bigger regions first so smaller regions can still be seen
    stats_in = mask;
    if strcmp(sort_by, 'area')
        [~, idx] = sort([stats_in.Area], 'descend');
        stats_in = stats_in(idx);
    end
    
    M = length(stats_in);
    stats = struct('Area', 0, 'PixelIdxList', cell(M,1));
    parfor i=1:M
        if stats_in(i).Area == 0
            continue;
        end
        mask = bia.convert.stat2im(stats_in(i), sz);
        boundary_labeled = fun_boundary(mask); %#ok<PFBNS>
        if border_thickness > 1
            boundary_labeled = imdilate(boundary_labeled, ones(border_thickness));
        end
        stats(i) = regionprops(uint8(boundary_labeled), 'Area', 'PixelIdxList');
    end
else
    boundary_labeled = fun_boundary(mask);
    if border_thickness > 1
        boundary_labeled = imdilate(boundary_labeled, ones(border_thickness));
    end
    boundary_labeled = single(boundary_labeled).*single(mask);
    stats = regionprops(boundary_labeled, 'Area', 'PixelIdxList');
end

idx_active = find([stats(:).Area]>0);
N = sz(1)*sz(2);
colors = alpha*255*bia.utils.colors(cmap, max(idx_active));
for i=idx_active
    idx         = stats(i).PixelIdxList;
    im(idx)     = colors(i, 1);
    im(idx+N)   = colors(i, 2);
    im(idx+2*N) = colors(i, 3);
end
end