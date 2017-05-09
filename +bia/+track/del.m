function [stats, idx_kept] = del(stats, min_len)
% deletes tracks with length <= min_len

[t_start, t_end] = bia.track.ends(stats);
track_lens = t_end-t_start+1;
idx_rm = track_lens <= min_len;
idx_kept = setdiff(1:length(t_start), idx_rm);
for t=1:length(stats)
    stats{t}(idx_rm) = [];
end

end