function proposals(opts, stats, ims)
% plots proposal boundaries on image

% mode: 1, proposal boundaries in a single image, level is represented by different colors
% mode: 2, [im, lvl1, lvl2, ...], proposal boundaries for a single level ar shown
% mode: 4, shows proposal levels in 3d. [Not recommended]
%
sz  = [size(ims{1},1), size(ims{1},2)];
T = length(ims);

opts_default  = struct('mode',1,'cmap','prism','border_thickness',1,'alpha',.5,'use_sqrt',0,'fun_boundary',@boundarymask,'save_path','','frame_rate',2);
opts                = bia.utils.updatefields(opts_default, opts);

frame_rate          = opts.frame_rate;
save_path           = opts.save_path;
save_video          = ~isempty(save_path);

mode             = opts.mode;
border_thickness = opts.border_thickness;
use_sqrt         = opts.use_sqrt;
fun_boundary     = opts.fun_boundary;% 1:bwperim (thinner and complete boundaries) 2: boundarymask (thick but may have holes)
alpha   = opts.alpha;
cmap    = opts.cmap;
colors  = alpha*255*bia.utils.colors(cmap);


save_video = save_video && mode == 1;
if mode == 1
    [fig_h1, ax_h1] = bia.plot.fig('Proposals',1);
end
if mode == 2
    [fig_h2, ax_h2] = bia.plot.fig('Proposals', [2 3]);
end
if mode == 4
    [fig_h4, ax_h4] = bia.plot.fig('Proposals_3D');
end

if save_video
    caps = cell(T,1);
end
for t = 1:T
    fprintf('%d ',t)
    s   = stats{t};
    if use_sqrt
        im  = uint8(255*bia.prep.norm(sqrt(single(ims{t}))));
    else
        im  = ims{t};
    end
    if isfield(s,'level')
        lvl = [s(:).level];
        lvls= sort(unique(lvl), 'descend');
        lvls(lvls > 5) = [];
    else
        [~,idx] = sort([s(:).Area], 'descend');
        s = s(idx);
        lvls = 1;
        lvl = ones(length(idx),1);
    end
    
    iml = zeros(sz);
    if mode == 2
        for i=1:length(ax_h2)
            cla(ax_h2(i),'reset')
        end
        imshow(im, 'Parent', ax_h2(1))
    end
    if mode == 1
        for i=1:length(ax_h1)
            cla(ax_h1(i),'reset')
        end
    end
    for i=bia.utils.row_vec(lvls)
        idx = lvl==i;
        ss = s(idx);
        if mode == 4
            imOnXY = label2rgb(bia.convert.stat2im(ss,sz),'lines','w');
            w = 5;
            imOnXY(:, 1:w, :) = 0;
            imOnXY(1:w, :, :) = 0;
            imOnXY(:, end-w:end, :) = 0;
            imOnXY(end-w:end, :, :) = 0;
            x=0*im+10*i;
            surface(ax_h4,x,imOnXY,'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct')
            view(-35,45)
        end
        imn     = i*fun_boundary(bia.convert.stat2im(ss, sz));
        if border_thickness > 1
            imn = imdilate(imn, ones(border_thickness));
        end
        if mode == 2
            im2 = repmat(im, [1 1 3]);
            N = prod(sz);
            st = regionprops(imn, 'PixelIdxList');
            color_id    = 2;
            idx         = st(i).PixelIdxList;
            im2(idx)     = colors(color_id, 1);
            im2(idx+N)   = colors(color_id, 2);
            im2(idx+2*N) = colors(color_id, 3);
            imshow(im2, 'Parent', ax_h2(i+1))
        end
        if mode == 1
            iml(imn>0)     = imn(imn>0);
        end
    end
    
    if mode == 1
        st = regionprops(iml, 'PixelIdxList');
        im2 = repmat(im, [1 1 3]);
        N = prod(sz);
        for i=length(st):-1:1
            color_id    = rem(i, size(colors,1))+1;
            idx         = st(i).PixelIdxList;
            im2(idx)     = colors(color_id, 1);
            im2(idx+N)   = colors(color_id, 2);
            im2(idx+2*N) = colors(color_id, 3);
        end
        imshow(im2, 'Parent', ax_h1)
    end
    drawnow
    if save_video
        caps{t} = bia.save.getframe(fig_h1);
    end
end
fprintf('\n')
if save_video
    bia.save.video(caps, sprintf('%s_proposals_mode%d.avi', save_path, mode), frame_rate)
end
end