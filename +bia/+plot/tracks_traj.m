function tracks_traj(opts, ax, stats_tra, trajs, t)
% plots trajectory of tracks in a window around given 't'
% 

opts_default= struct('alpha', 1, 'line_width', 1, 'cmap', 'prism', 'traj_len', [5 0]);
opts        = bia.utils.updatefields(opts_default, opts);
alpha       = opts.alpha;
cmap        = opts.cmap;
line_width  = opts.line_width;
n_past      = opts.traj_len(1);
n_future    = opts.traj_len(2);

T           = length(stats_tra);

t_past      = max(1,t-n_past);
t_future    = min(T,t+n_future);

% tra_cur     = find([stats_tra{t}.Area]>0);% tracks in current frame
tra_past    = bia.track.tracks_active(stats_tra(t_past:t));
tra_future  = bia.track.tracks_active(stats_tra(t:t_future));
tra_all     = intersect(tra_past, tra_future);% track ids which occur in both previous and future time

colors      = alpha*bia.utils.colors(cmap, max(tra_all));

for i=tra_all
    t_idx       = ismember(trajs{i}(:,3), t_past:t_future);
    plot(ax, trajs{i}(t_idx,1), trajs{i}(t_idx,2), 'color', colors(i,:), 'LineWidth', line_width)
end
end
