function [b,b1] = brier(stats)
b = 0;
b1= 0;
count = 0;
count1= 0;

if iscell(stats)
    for t=1:length(stats)
        for i=1:length(stats{t})
            b = b + (stats{t}(i).Score-stats{t}(i).Label)^2;
            count = count + 1;
            if stats{t}(i).Label == 1
                b1 = b1 + (stats{t}(i).Score-stats{t}(i).Label)^2;
                count1 = count1 + 1;
            end
        end
    end
else
    edges = stats;
    count =0;
    count1=0;
    b = 0;
    b1 = 0;
    for i=1:size(edges,1)
        count = count+1;
        if edges(i,5) == 1 || edges(i,5) == 2
            b1 = b1 + (edges(i,4)-1)^2;
            count1 = count1+1;
            label = 1;
        else
            label = 0;
        end
        b = b + (edges(i,4)-label)^2;
    end
end
b = b/count;
b1= b1/count1;
end