function gaps = gaps(stats)
% returns the gaps due to missed detections in the tracks
% 
%     gaps.start = [trackID, time] : times with 1st missed detetcion (FN)
%         .end = [trackID, time]: times with 1st detection after FN
% 

[t_start, t_end] = bia.track.ends(stats);
K = length(t_start);

gaps = struct('start',[],'end',[]);
for k=1:K
    for t=t_start(k)+1:t_end(k)-1
        if stats{t}(k).Area == 0 && stats{t-1}(k).Area > 0
            gaps.start = [gaps.start; k t];
        end
        if stats{t}(k).Area == 0 && stats{t+1}(k).Area > 0
            gaps.end = [gaps.end; k t];
        end
    end
end
end

