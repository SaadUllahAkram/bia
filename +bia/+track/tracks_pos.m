function traj = tracks_pos(stats)
% returns pos of tracks as a cell array
%   Each tracks pos is returned as -> [x y z (3D only) t]
% 
tra_id = bia.track.tracks_active(stats);

[t_start, t_end] = bia.track.ends(stats);

dims = length(stats{1}(1).Centroid) + 1;

traj = cell(max(tra_id), 1);
for i = tra_id
    traj{i} = zeros(t_end(i) - t_start(i)+1, dims);
    for t = 1:length(stats)
        if t >= t_start(i) && t <= t_end(i)
            row = t-t_start(i)+1;
            if stats{t}(i).Area > 0
                traj{i}(row,:) = [stats{t}(i).Centroid, t];
            else
                traj{i}(row,:) = [traj{i}(row-1,1:end-1), t];% get prev. position in case track is missing
            end
        end
    end
end
end
