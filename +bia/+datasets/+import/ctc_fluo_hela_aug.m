function ctc_fluo_hela_aug()
close all
paths = get_paths();
root_exp = fullfile(paths.data_mat.root1, sprintf('v%d',1));
bia.save.mkdir(root_exp)
dataset = 'Fluo-N2DL-HeLa';
opts_seg = struct('use_sqrt', 1,'hmin',2, 'min_size', 30,'max_size', 3000, 'opening', 4, 'win', 29, 'contrast_thresh', 1, 'min_intensity', 30, 'add_fn_bbox',0, 'bbox_size', 20);%hela
% opts_seg = struct('use_sqrt', 0,'hmin',2, 'min_size', 50,'max_size',11000, 'opening', 2, 'win', 59, 'contrast_thresh', 4, 'min_intensity', 30, 'add_fn_bbox',0, 'bbox_size', 65);%gowt1
opts_seg = bia.utils.setfields(opts_seg, 'debug',0);

[~, hax] = bia.plot.fig('CTC Augmentation');
for s=1:2
    seq_num = sprintf('%02d', s);
    seq_name_full = [dataset, '-', seq_num];
    fprintf('%s\n', seq_name_full)
    [gt, ims] = bia.datasets.load(seq_name_full);
    if isempty(gt)
        warning('data was not loaded for: %s', seq_name_full)
        continue
    end
    T = gt.T;
    
    stats_seg = cell(T,1);
    fn = zeros(1,T);
    tp = zeros(1,T);
    num_gt = zeros(1,T);
    num_seg = zeros(1,T);
    fn_ids = cell(T,1);
    for t=1:T
        bw = bia.external.bernsen_threshold(opts_seg, ims{t});
        bw = imerode(bw, ones(3));
        if gt.seg.info(t,3) == 0% process ONLY unsegmented or partially segmented frames
            sz = gt.sz(t,:);
            rel = -bwdist(~bw);
            % rel = -single(ims{t});
            rel = imhmin(rel, opts_seg.hmin);
            cent = bia.convert.centroids(gt.tra.stats{t});
            cent_idx = sub2ind(sz, round(cent(:,2)), round(cent(:,1)));
            fg = zeros(sz);
            for i=1:length(gt.tra.stats{t})
                fg(gt.tra.stats{t}(i).PixelIdxList) = 1;
            end
            fg = fg.*bw;
            bg = imerode(~bw, ones(5));
            rel = imimposemin(rel, bg | fg);
            ws = watershed(rel);
            ws1 = bwlabeln(logical(ws));% re-label connected components
            s1 = bia.stats.regions(ws);
            s2 = bia.stats.regions(ws1);
            oo = bia.utils.overlap_pixels(s1,s2);
            assert(isequal(size(oo,1), size(oo,2)))
            assert(isequal(size(oo,1), bia.utils.ssum(oo)))
            % delete small and dark bg region
            stats = regionprops(ws, ims{t}, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList', 'MeanIntensity');
            bg_ids = unique(ws(bg))';
            idx_del = [];
            for i=bg_ids% delete dark bg regions: retains large bright bg regions (are mostly cells)
                if stats(i).MeanIntensity < opts_seg.min_intensity
                    idx_del = [idx_del, i];
                end
            end
            
            area_del = find([stats.Area]< opts_seg.min_size);
            idx_del = [idx_del, area_del];
            for i = idx_del
                ws(stats(i).PixelIdxList) = 0;
            end
            stats(idx_del) = [];
            
            if opts_seg.add_fn_bbox% adds fixed size box for FN markers: WARNING: Does not add masks only a fixed size bbox
                vals = ws(cent_idx);
                fn_markers = find(vals == 0);
                for i=1:length(fn_markers)
                    cc = cent(fn_markers(i), :);
                    stats(end+1,1).BoundingBox = [max(1, cc(1)-opts_seg.bbox_size/2), max(1,cc(2)-opts_seg.bbox_size/2), opts_seg.bbox_size, opts_seg.bbox_size];
                    stats(end,1).Area = 10;
                end
            end
            stats = bia.struct.standardize(stats);
            % remove regions having no overlap with a gt marker
            overlaps = bia.utils.overlap_pixels(gt.tra.stats{t}, stats);
            overlaps_regions = max(overlaps,[],1);% best iou of a seg. region with any GT marker
            idx_bg_rm = find(overlaps_regions == 0);
            if ~isempty(idx_bg_rm)
                stats(idx_bg_rm) = [];
            end
            stats_seg{t} = stats;
            
            [fn(t), tp(t), num_gt(t), fn_ids{t}] = eval_seg(gt.tra.stats{t}, stats);
            num_seg(t) = length(stats);
            if opts_seg.debug
                fprintf('t:%3d, #GT:%4d, #Segmented:%4d, FN:%4d, TP:%4d\n', t, num_gt(t), num_seg(t), fn(t), tp(t))
                imshow(bia.draw.boundary(struct('alpha',1), bia.prep.norm(ims{t},'sqrt'), stats), 'parent', hax)
                bia.plot.bb(hax, stats)
                bia.plot.centroids(hax, gt.tra.stats{t}(fn_ids{t},1))
                drawnow
            end
        else
            stats_seg{t} = gt.seg.stats{t};
        end
    end
    fprintf('Sequence: %s, #GT: %6d, #Segmented: %6d, #FN: %d\n', seq_name_full, sum(num_gt), sum(num_seg), sum(fn))
    gt.seg.stats = stats_seg;
    gt.seg.info = [(1:gt.T)', ones(gt.T, 2)];
    save(fullfile(root_exp, [seq_name_full, '-GT.mat']), 'gt')
end
end


function [fn, tp, num_gt, fn_ids] = eval_seg(gt, seg)
num_gt = sum([gt.Area] > 0);
overlaps = bia.utils.overlap_pixels(gt, seg, 0.5);
overlaps_markers = max(overlaps,[],2);
tp = sum(overlaps_markers > 0);
fn_ids = find(overlaps_markers == 0 & [gt.Area]' > 0);
fn = num_gt - tp;
end