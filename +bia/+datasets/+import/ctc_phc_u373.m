function ctc_phc_u373()
% uses unet and graph cuts to augment segmentation data

dbg = 0;
paths = get_paths();

dataset = 'PhC-C2DH-U373';

root_exp = fullfile(paths.data_mat.root1, sprintf('v%d',1));
bia.save.mkdir(root_exp)


if dbg
    [h1,a1] = bia.plot.fig('unet');
    [h2,a2] = bia.plot.fig('gc');
    [h3,a3] = bia.plot.fig('gt');
end
for s=1:2
    seq = sprintf('%s-%02d', dataset, s);
    fprintf('%s\n', seq)
    [gt, ims] = bia.datasets.load(seq);
    if isempty(gt)
        warning('data was not loaded for: %s', seq)
        continue
    end
    unet = fullfile(paths.save.unet, [seq, '.mat']);
    gc = fullfile(paths.save.phc_gc, [seq, '.mat']);
    if ~exist(unet, 'file')
        warning('unet results not found at: %s', unet)
        return
    end
    if ~exist(gc, 'file')
        warning('graph cut results not found at: %s', gc)
        return
    end
    stats_unet = load(unet);
    stats_gc = load(gc);
    stats_unet = stats_unet.stats_tra;
    stats_gc = stats_gc.stats_tra;
    
    gt_stats = cell(gt.T,1);
    gt_info = ones(gt.T, 3);
    gt_info(:,1) = 1:gt.T;
    for t=1:gt.T
        if gt.seg.info(t,3) == 1
            gt_stats{t} = gt.seg.stats{t};
        else
            skip = 0;
            mun = bia.utils.match('', gt.tra.stats{t}, stats_unet{t}, gt.sz(t,1:2));
            mgc = bia.utils.match('', gt.tra.stats{t}, stats_gc{t}, gt.sz(t,1:2));
            for i=1:size(mun,1)% gt
                if gt.tra.stats{t}(i).Area == 0
                elseif sum(mun(i,:)) == 1
                    idx = mun(i,:)>0;
                    gt_stats{t}(i,1) = stats_unet{t}(idx);
                elseif sum(mgc(i,:)) == 1
                    idx = mgc(i,:)>0;
                    gt_stats{t}(i,1) = stats_gc{t}(idx);
                else
                    skip = 1;
                    gt_info(t,3) = 0;
                    if dbg
                        warning('seq: %d, t: %3d, id: %3d', s, t, i)
                    end
                end
            end
        end
        gt_stats{t} = bia.struct.standardize(gt_stats{t}, 'seg', 2);
        if dbg
            imshow(bia.draw.boundary([], ims{t}, gt_stats{t}),'parent',a3)
            bia.plot.centroids(a3, gt.tra.stats{t})
            set(h3,'name',sprintf('gt: t:%3d', t),'numbertitle','off')
            drawnow
            if skip == 1 
                imshow(bia.draw.boundary([], ims{t}, stats_unet{t}),'parent',a1)
                imshow(bia.draw.boundary([], ims{t}, stats_gc{t}),'parent',a2)
                t;
            end
        end
    end
    gt.seg.stats = gt_stats;
    gt.seg.info = gt_info;
    save(fullfile(root_exp, [seq, '-GT.mat']), 'gt')
end