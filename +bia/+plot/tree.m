function tree(h_fig, im, stats, tree_id, gt_detect, stats_cell, labels_cell)

% mode: 
%     proposals at different tree levels
%     proposals in the same image. [tip to root]
% Print
%     score
%     id
%     
% Level-> 1:root of a tree

font_size = 20;
if isempty(h_fig)
    h_fig = gcf;
end
sz    = [size(im,1), size(im,2)];
trees = [stats.tree];

if ~exist('stats_cell', 'var')
    num_detect = 0;
else
    num_detect = length(stats_cell);
end

if ~exist('gt_detect', 'var')
    plot_gt_markers = 0;
elseif isempty(tree_id)
    plot_gt_markers = 0;
else
    plot_gt_markers = 1;
end

if ~exist('tree_id', 'var')
    plot_all_trees = 1;
elseif isempty(tree_id)
    plot_all_trees = 1;
else
    plot_all_trees = 0;
end

if plot_all_trees
    idx   = 1:length(trees);
else
    idx   = find(trees == tree_id);
end

bb    = bia.convert.bb(stats(idx), 's2r');
r     = rect(bb);
% imr   = extract(im, r);
l     = [stats(idx).level];
lvls  = sort(unique(l));

x     = length(lvls) + num_detect;
of = [1 4 5 2 3];
for i=1:length(lvls)
    h = bia.plot.subplot(1,x,i,h_fig);
    st = stats(idx(l==i));
    imx = bia.draw.boundary(struct('alpha',1,'border_thickness',2), im, st);
    imshow(imx, 'Parent', h)
    title(sprintf('Level : %d', i),'FontSize',font_size)
    bia.plot.number(h, struct('color','g','font_size',24,'bg_color','k','type',5), st, of(l==i));%plot tree_ids    
%     bia.plot.number(h, struct('color','g','font_size',8,'bg_color','none','type',5), st, 'tree');%plot tree_ids
%     bia.plot.number(h, struct('color','g'), st, 'Score')
%     bia.plot.number(h, struct('color','g','font_size',8,'bg_color','none','type',5), st, idx(l==i))
    if plot_gt_markers
        bia.plot.centroids(h, gt_detect)
    end
    axis(h, r([3 4 1 2]))
end

if num_detect~= 0
    for i=1:length(stats_cell)
        h = bia.plot.subplot(1,x,x-i+1,h_fig);
        if plot_all_trees
            st = stats_cell{i};
        else
            st = stats_cell{i}([stats_cell{i}.tree] == tree_id);
        end
        imx = bia.draw.boundary([], im, st);
        imshow(imx, 'Parent', h)
        bia.plot.number(h, struct('color','g'), st, 'Score')
        axis(h, r([3 4 1 2]))
        title(sprintf(labels_cell{i}),'FontSize',font_size)
    end
end
end

function imr = extract(im, r)
imr = im(r(1):r(2), r(3):r(4), :);
end

function r1 = rect(r)
r1 = [min(r(:,1)), max(r(:,2)), min(r(:,3)), max(r(:,4))];
end