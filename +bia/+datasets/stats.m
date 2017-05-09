function s = stats(opts, gt)
% prints some stats about the given dataset
% 
% Inputs:
%     opts:
%     gt: Ground truth data structure
%     
% Outputs:
%     s : stats
%     
opts_default = struct('verbose',1,'hist',0,'ar_mode',1,'max_move',8,'move_plots',0);
opts = bia.utils.updatefields(opts_default, opts);
verbose = opts.verbose;
plot_hists = opts.hist;
ar_mode = opts.ar_mode;% 1: transform aspect ratio so that all are '>= 1'
max_move = opts.max_move;% ignore moves larger than "plot_hist*std_move distance"
move_plots = opts.move_plots;% how speed and dir changes

T = gt.T;

s = struct();
% tracking stats
if isfield(gt,'tra')
    n_tracks = size(gt.tra.info, 1);
    n_list = arrayfun(@(x) sum([x{1}.Area] > 0), gt.tra.stats);% # tra markers
    N = sum(n_list);
    [parents,~,exit,~,enter] = bia.track.events([], gt.tra.info);
    n_mitosis = length(parents);
    n_enter = length(enter);
    n_exit = length(exit);
    n_mitosis_edges = sum(gt.tra.info(:,4)>0);
    move_stats = dist_stats(gt, n_tracks, max_move);
    n_move_edges = length(move_stats.data);
    s = bia.utils.setfields(s,'n_tracks',n_tracks,'n_markers',N,'n_mitosis',n_mitosis,'n_enter',n_enter,'n_exit',n_exit,'n_mitosis_edges',n_mitosis_edges,...
        'move_stats',move_stats,'n_move_edges',n_move_edges);
    if move_plots
       move_dirs(gt);
    end
end
% mask stats
if isfield(gt,'seg')
    if ~isempty(gt.seg.stats)
        n_fully_seg = sum(gt.seg.info(:,3));
        n_seg = sum(gt.seg.info(:,2));
        m_fully_list = arrayfun(@(x) sum([x{1}.Area] > 0), gt.seg.stats(gt.seg.info(:,3)==1));% # fully seg masks
        MF = sum(m_fully_list);
        m_list = arrayfun(@(x) sum([x{1}.Area] > 0), gt.seg.stats);% # seg masks
        M = sum(m_list);
        [area_stats, bb_stats] = mask_stats(gt, ar_mode);

        % pixel counts
        [fg_pixels, bg_pixels, num_pixels] = pixel_count(gt);
        s = bia.utils.setfields(s,'n_fully_seg',n_fully_seg,'n_seg',n_seg,'n_masks',M,'area_stats',area_stats,'bb_stats',bb_stats,'fg_pixels',fg_pixels,'bg_pixels',bg_pixels);
    else
        gt = rmfield(gt, 'seg');
    end
end

% mask stats
if isfield(gt,'detect')
    n_list = arrayfun(@(x) size(x{1},1), gt.detect);% # tra markers
    N = sum(n_list);
    s = bia.utils.setfields(s,'n_markers',N);
end

if verbose
    sz_max = max(gt.sz);
    sz_min = max(gt.sz);
    bia.print.fprintf('red', '%s, T: %d, sz -> min:[%d %d %d] - max[%d %d %d]\n', gt.name, T, sz_min(1), sz_min(2), sz_min(3), sz_max(1), sz_max(2), sz_max(3))
    if isfield(gt,'tra')
        fprintf('Markers: %d (min:%d, max:%d), #Tracks: %d, Events: #Mitosis: %d, #Enter: %d cells, #Exit: %d\n', N, min(n_list(gt.tra.tracked)), ...
            max(n_list(gt.tra.tracked)), n_tracks, n_mitosis, n_enter, n_exit)
        fprintf('Move Distances:: Min:%1.1f, Max:%1.1f, Mean:%1.3f, Std:%1.3f\n', move_stats.min, move_stats.max, move_stats.mu, move_stats.std)
        if plot_hists
            [~,hax_move] = bia.plot.fig(sprintf('Moved Distance: Deleted:%d of %d', move_stats.ignored, move_stats.ignored+length(move_stats.data)),1,1,0);
            histogram(hax_move, move_stats.data, 25)
        end
    end
    if isfield(gt,'seg')
        fprintf('Fully Seg: %d frames with %d masks, Fully+Partial Seg: %d frames with %d masks\n', n_fully_seg, MF, n_seg, M)
        fprintf('%% Pixels: FG: %1.3f, BG: %1.3f\n', fg_pixels, bg_pixels)
        fprintf('Masks: Areas:: Min:%d, Max:%d, Mean:%1.3f, Std:%1.3f\n', area_stats.min, area_stats.max, area_stats.mu, area_stats.std)
        fprintf('Masks: BBoxes:: Min:%d, Max:%d, Mean:%1.3f, Std:%1.3f\n', bb_stats.min, bb_stats.max, bb_stats.mu, bb_stats.std)
        fprintf('Masks: AspectRatios:: Min:%1.3f, Max:%1.3f, Mean:%1.3f, Std:%1.3f\n', bb_stats.aspect_ratio.min, bb_stats.aspect_ratio.max, bb_stats.aspect_ratio.mu, bb_stats.aspect_ratio.std)
        if plot_hists
            [~,hax_area] = bia.plot.fig('Area',1,1,0);
            histogram(hax_area, area_stats.data)
            
            [~,hax_bb] = bia.plot.fig('Bounding Box',1,1,0);
            histogram(hax_bb, bb_stats.data)
            
            [~,hax_ar] = bia.plot.fig('Aspect Ratio',1,1,0);
            histogram(hax_ar, bb_stats.aspect_ratio.data)
        end
    end
end

if nargout == 0
    clear s
end
end


function [area_stats, bb_stats] = mask_stats(gt, ar_mode)
T = length(gt.seg.stats);

areas = cell(T,1);
bbs = cell(T,1);
for t=1:T
    areas{t} = [gt.seg.stats{t}.Area]';
    areas{t} = areas{t}(areas{t} > 0);
    bbs{t} = bia.convert.bb(gt.seg.stats{t}, 's2b');
end
areas = cell2mat(areas);
bbs = cell2mat(bbs);

aspect = bbs(:,3)./bbs(:,4);
if ar_mode
    aspect(aspect < 1) = 1./aspect(aspect < 1);
end

bbs = bbs(:,3:4);

area_stats = compute_stats(areas);
bb_stats = compute_stats(bbs(:));
bb_stats.aspect_ratio = compute_stats(aspect);
bb_stats.bb = bbs;
end


function move = dist_stats(gt, n_tracks, max_move)
s = gt.tra.stats;
T = gt.T;
distances = cell(T-1,1);
idxs = cell(T,1);
c = cell(T,1);
for t=1:T
    [c{t,1}, idxs{t,1}] = bia.convert.centroids(s{t});
end
dim = size(c{1},2);
moves = zeros(T, n_tracks);% cell level distances (i=time,j=cell_id)
active = zeros(T, n_tracks);% active cell (i=time,j=cell_id)
for t=1:T-1
    idx = intersect(idxs{t}, idxs{t+1});
    n = max(max(idxs{t}), max(idxs{t+1}));
    cents_t = zeros(n, dim);
    cents_n = zeros(n, dim);
    cents_t(idxs{t},:) = c{t};
    cents_n(idxs{t+1},:) = c{t+1};
    d = dist(cents_t, cents_n);
    distances{t} = d(idx);
    moves(t, idx) = d(idx);
    active(t, idx) = 1;
end
distances = cell2mat(distances);
move = compute_stats(distances);
idx_del = abs(move.data) > move.mu + max_move*move.std;
move.outliers = move.data(idx_del);
move.data(idx_del) = [];
move.ignored = sum(idx_del);
end


function s = compute_stats(x)
mu = mean(x);
sigma = std(x);
m1 = min(x);
m2 = max(x);
s = struct('mu', mu, 'std', sigma, 'min', m1, 'max', m2, 'data', x);
end


function d = dist(c1,c2)
dim = size(c1,2);
n = size(c1,1);
m = size(c2,1);
if m~=n
    d = zeros(max(m,n),1);
    return
end
d = zeros(n,1);
for i=1:dim
    d = d + (c1(:,i) - c2(:,i)).^2;
end
d = sqrt(d);
end


function move_dirs(gt)
T = gt.T;
velocity_c = cell(T-1, 1);
direction_c = cell(T-1, 1);
speed_c = cell(T-1, 1);
for t=1:T-1
    cents1 = reshape([gt.tra.stats{t  }.Centroid], 2, [])';
    cents2 = reshape([gt.tra.stats{t+1}.Centroid], 2, [])';
    n1 = size(cents1, 1);
    n2 = size(cents2, 1);
    n = max(n1, n2);
    if n1<n
        cents1 = [cents1;NaN(n-n1, 2)];
    elseif n2<n
        cents2 = [cents2;NaN(n-n2, 2)];
    end
    velocity_c{t} = cents2-cents1;
    direction_c{t} = (180/pi)*atan2(velocity_c{t}(:,2), velocity_c{t}(:,1));
    speed_c{t} = sqrt(sum(velocity_c{t}.^2, 2));
end

velocity_dif = [];% change in velocity
dir_dif = [];
speed_diff = [];
for t=1:T-2
    for k=1:size(velocity_c{t},1)
        v1 = velocity_c{t}(k,:);
        v2 = velocity_c{t+1}(k,:);
        if ~sum(isnan(v1)) && ~sum(isnan(v2))
            velocity_dif = [velocity_dif; v2-v1];
            dir_dif = [dir_dif; direction_c{t+1}(k) - direction_c{t}(k)];
            speed_diff = [speed_diff; speed_c{t+1}(k) - speed_c{t}(k)];
        end
    end
end
figure(1);histogram(dir_dif);title('Change in direction between 2 frames')
figure(2);histogram(speed_diff);title('Change in speed between 2 frames')

dir = (180/pi)*atan2(velocity_dif(:,2), velocity_dif(:,1)) + 180;%0-360
speed = sqrt(sum(velocity_dif.^2, 2));
m2 = ceil(prctile(speed,99));
speed(speed>m2) = m2;
WindRose(dir, speed, struct('freqlabelangle',30,'ndirections',24));
end


function [fg_pixels, bg_pixels, num_pixels] = pixel_count(gt)
tlist = gt.seg.info(gt.seg.info(:,3)==1,1)';
b = gt.foi_border;
fg_pixels = 0;
bg_pixels = 0;
for t=tlist
    im = bia.convert.stat2im(gt.seg.stats{gt.seg.info(:,1)==t}, gt.sz(t,:));
    im = im(b+1:gt.sz(t,1)-b, b+1:gt.sz(t,2)-b);
    fg_pixels = fg_pixels + sum(im(:)>0);
    bg_pixels = bg_pixels + sum(im(:)==0);
end
num_pixels = fg_pixels + bg_pixels;
fg_pixels = fg_pixels/num_pixels;
bg_pixels = bg_pixels/num_pixels;
end