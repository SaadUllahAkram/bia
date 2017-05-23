function tracks(opts, ims, stats_tra, stats_info, gt)
% modes:
% 1-> plot3 -> x,y,t
% 2-> [im+traj]
% 3-> [cell borders+traj]
% 4-> [bia.convert.l2rgb+traj]
% 
% Inputs:
%     opts :
%     ims : a cell array of images
%     stats_tra {Area, Centroid, PixelIdxList, BoundingBox}: a cell array of structs, each cell has a unique id (idx in struct)
%     stats_gt : use GT to highlight errors : Segmentation [FP/FN/UnderSeg]/ Tracking [Wrong association/Missed events(Enter/Leave/Mitosis/Apoptosis)]
%
% ToDo:: highlight errors/events -> mitosis/apoptosis/enter/leave
%

opts_default = struct('mode',0,'show_im',0,'save_path','','rect',[],'use_sqrt',0,'verbose',1,'frame_rate',2,...
    'opts_traj', struct('traj_len', [15 0],'line_width',1.5,'alpha',.5), ...
    'opts_boundary', struct('cmap','prism','border_thickness',1,'alpha',0.5,'fun_boundary',@boundarymask));
opts                = bia.utils.updatefields(opts_default, opts);

frame_rate          = opts.frame_rate;
opts_traj           = opts.opts_traj;
opts_boundary       = opts.opts_boundary;
save_path           = opts.save_path;
save_video          = ~isempty(save_path);
mode                = opts.mode;
show_im             = opts.show_im;
rect                = opts.rect;
use_sqrt            = opts.use_sqrt;
verbose             = opts.verbose;

if nargin >= 5
    foi_border = gt.foi_border;
else
    foi_border = 0;
end

if nargin >= 4 && ~isempty(stats_info)
    plot_events = true;
else
    plot_events = false;
end
if use_sqrt
    fun_im = @(x) bia.prep.norm(x, 'sqrt');
else
    fun_im = @(x) bia.prep.norm(x);
end
T                   = length(ims);
trajs               = bia.track.tracks_pos(stats_tra);

if ~isempty(rect)
    assert(sum(rect([1 3]) >= [1 1]) == 2)
    assert(sum(rect([2 4]) <= [size(ims{1},1) size(ims{1},2)]) == 2)
end
if save_video
    caps = cell(T,1);
end
if mode == 1
    [fig_h_1,ax_h_1] = bia.plot.fig('Tracking Results: Full Trajectories');
    hold on
    for i=1:length(trajs)
        plot3(ax_h_1, trajs{i}(:,1), trajs{i}(:,2), trajs{i}(:,3))
    end
    xlabel('X')
    ylabel('Y')
    zlabel('Time')
    drawnow
    saveas(fig_h_1, [save_path, '_plot3.fig'])
elseif ismember(mode, [2 3 4])
    if isempty(rect)
        [fig_h, ax_h] = bia.plot.fig('Tracking Results: 2D', [1, 1+show_im]);
        figure(fig_h); 
        % fullscreen
        if 0
            set(fig_h, 'Units', 'Pixels')
            set(ax_h, 'Units', 'Pixels')
            set(fig_h, 'OuterPosition', [0 0 size(ims{1}, 2)+100 size(ims{1}, 1)+200])
            set(ax_h, 'Position', [25 25 size(ims{1}, 2) size(ims{1}, 1)])
        end
    else
        fig_h = figure(1);fullscreen
        ax_h(1) = subplot(1,2,1);hold on
        ax_h(2) = subplot(1,2,2);hold on
    end
    for t=1:T
        if verbose
            fprintf('%d ',t)
        end
        for k=1:length(ax_h)
            cla(ax_h(k), 'reset')
            cla(ax_h(k))
        end
        im = fun_im(ims{t});
        sz = [size(im, 1), size(im, 2)];
        if show_im
            imshow(im, [], 'parent', ax_h(1))
            if ~isempty(rect)
                axis(ax_h(1), rect([3:4, 1:2]))
            end
        end
        if mode == 2
            im2 = im;
        elseif mode == 3
            im2 = bia.draw.boundary(opts_boundary, im, bia.convert.stat2im(stats_tra{t}, sz));
        elseif mode == 4
            im2 = bia.convert.l2rgb(bia.convert.stat2im(stats_tra{t}, sz));
        end
        im2 = bia.draw.roi(struct('out',[0 0 0]), im2, foi_border);
        % im3 = bia.draw.tracks_traj(opts_traj, im2, stats_tra, trajs, t);%todo: does not plot images
        
        imshow(im2, 'parent', ax_h(end))
        hold(ax_h(end), 'on')
        axis(ax_h(end), [1 sz(2) 1 sz(1)])
        bia.plot.tracks_traj(opts_traj, ax_h(end), stats_tra, trajs, t);
        if plot_events
            if t~= 1
                draw_box(ax_h(end), t, stats_tra{t}, stats_info, 1)
            end
            if t~= T
                draw_box(ax_h(end), t, stats_tra{t}, stats_info, 2)
            end
            draw_box(ax_h(end), t, stats_tra{t}, stats_info, 3)
            draw_box(ax_h(end), t, stats_tra{t}, stats_info, 4)
        end
        
        if ~isempty(rect)
            axis(ax_h(end), rect([3:4, 1:2]))
        end
        drawnow
        if save_video
            caps{t} = bia.save.getframe(fig_h);
        end
    end
    if verbose
        fprintf('\n')
    end
    if save_video
        bia.save.video(caps, sprintf('%s_2d_mode%d.avi', save_path, mode),frame_rate)
        save(sprintf('%s_2d_mode%d.mat', save_path, mode), 'caps')
    end
end
end


function draw_box(ax, t, stats, info, type, varargin)
ex = 5;% how to expand the boxes

[ids_mit, mitosis_t] = bia.track.events([], info);
ids_mit(mitosis_t~=t) = [];
ids_daughters = info(info(:,4)~=0 & info(:,2) == t, 1);
if type == 1%enter
    ids = info(info(:,2) == t, 1);
    ids = setdiff(ids, ids_daughters);% remove daughters
    col = 'g';
    curv = [0 0];
elseif type == 2%exit
    ids = info(info(:,3) == t, 1);
    ids = setdiff(ids, ids_mit);
    col = 'r';
    curv = [0 0];
elseif type == 3%parent
    ids = ids_mit;
    col = 'r';
    curv = [1 1];
elseif type == 4%daughters
    ids = ids_daughters;
    col = 'g';
    curv = [1 1];
end
line_width = 2;

if isempty(ids)
    return
end
for i=ids'
    b = stats(i).BoundingBox;
    b(1:2) = b(1:2) - ex;
    b(3:4) = b(3:4) + 2*ex;
    rectangle('Parent', ax, 'Position', b, 'EdgeColor', col, 'LineWidth', line_width,'Curvature',[curv], varargin{:})
end

end