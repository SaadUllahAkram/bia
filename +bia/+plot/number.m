function number(ax, opts, stats, field)
% plots the number is the given 'field'
% 
ax = get_axes(ax);

opts_default = struct('type',1,'bg_color','k','color','r','font_size',8);
opts = bia.utils.updatefields(opts_default, opts);

font_size = opts.font_size;
bg_color  = opts.bg_color;
color     = opts.color;

use_num = 0;
use_id  = 0;
if nargin < 4
    use_id = 1;
elseif isempty(field)
    use_id = 1;
elseif isnumeric(field)
    use_num = 1;
end

for i=1:length(stats)
    c = stats(i).Centroid;
    if stats(i).Area>0
        if use_id
            str = sprintf('%d', i);
        else
            if use_num
                scores = field(i);
            else
                scores = stats(i).(field);
            end
            if opts.type == 1% 0-1 -> 2 sig.
                str = sprintf('%1.2f', scores);
            elseif opts.type == 2% 0-1 ->0-100
                str = sprintf('%d', round(100*scores));
            elseif opts.type == 3% for scores greater than 1
                str = sprintf('%1.1f', scores);
            elseif opts.type == 4% for scores with very large range
                str = sprintf('%1.1f', log(scores));
            elseif opts.type == 5% int
                str = sprintf('%d', scores);
            end
        end
        text(ax, c(1), c(2), str, 'color', color, 'BackgroundColor', bg_color, 'FontSize', font_size)
    end
end
end