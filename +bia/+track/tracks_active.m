function active_ids = tracks_active(stats)
% returns tracks ids that are active within the given time window provided by stats.

active_ids = [];
for t=1:length(stats)
    active_ids = [active_ids, find([stats{t}.Area]>0)];
end
active_ids = unique(active_ids);

end
