function [t_start, t_end] = ends(stats)
% given tracks, returns the start and end times of each track
% 1-based indexing
% 

num_tra = max(cellfun(@(x) length(x), stats));
t_start = -ones(1,num_tra);
t_end   = -ones(1,num_tra);
for t=1:length(stats)
    for i=1:length(stats{t})
        if stats{t}(i).Area > 0
            if t_start(i) == -1% set the track start time
                t_start(i) = t;
            end
            t_end(i) = t;% set track end time
        end
    end
end

% if sum(t_start == -1)~=0
%     warning('t_start of some tracks is wrong')
% end
% if sum(t_end == -1)~=0
%     warning('t_end of some tracks is wrong')
% end

end
