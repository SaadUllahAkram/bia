function edges = dag(info, stats, t_tracked)
% returns edges in the graph given tracking stats/info
% 
% careful: "t_tracked" can contain ONLY 1 consecutuive tracked subsequence. will cause errors if more subsequences are in "t_tracked".
% 
% Inputs:
%     info: info of tracks: [id, t_start, t_end, parent]
%     stats: struct containing tracks data
%     t_tracked: array containing '1' in frame indices which were tracked
% Outputs:
%     edges = [from_t, to_t,from_id, to_id]
% 

if nargin == 2
    t_tracked = true(length(stats),1);
end

t_start = find(t_tracked==1,1);
t_end = find(t_tracked==1,1,'last');
t_len = t_end-t_start+1;

% handle cases when not all frames are tracked
info(info(:,3) < t_start,:) = [];% remove tracks which ended before tracked frames start
info(info(:,2) > t_end,:) = [];% remove tracks which start after tracked frames end
info(:,[2, 3]) = info(:,[2, 3]) - t_start + 1;% adjust time
info(info(:,3) > t_len, 3) = t_len;% adjust track end time
stats = stats(t_tracked);

track_ids = info(:,1);
n_tracks = max(track_ids);
t_active = ones(1, n_tracks);
T = max(info(:,3));

% add move links
edges_move = cell(T,1);
for t=1:T
    if ~t_tracked(t_start + t - 1);    continue;   end
    active_info_t = track_ids( info(:,2) < t & info(:,3) >= t);
    active_stats_t = find([stats{t}(:).Area] > 0);
    if t > 1
        active_tracks_t = intersect(active_stats_t, active_info_t);
        n_moves = length(active_tracks_t);
        edges_move{t} = zeros(n_moves, 4);
        for k=1:n_moves
            id = active_tracks_t(k);
            edges_move{t}(k,:) = [t_active(id), t, id, id];
        end
    end
    t_active(active_stats_t) = t;
end

% add parents links
row_daughters = find(info(:,4)>0); % row # where daughters are listed
n_mitosis = length(row_daughters);
edges_mitosis = zeros(n_mitosis, 4);
for k=1:n_mitosis
    r = row_daughters(k);
    edges_mitosis(k,:) = [t_active(info(r, 4)), info(r, 2), info(r, 4), info(r, 1)];
end

edges = [cell2mat(edges_move); edges_mitosis];

edges(:, [1, 2]) = edges(:, [1, 2]) + t_start - 1;
end