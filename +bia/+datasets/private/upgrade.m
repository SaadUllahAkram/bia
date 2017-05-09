function gt = upgrade(gt, seq_name, version)
% import_old_gt(dataset, scale, save_mat, use_ws)
gt_v1 = gt;
gt = gt_v1;% gt: version 2: of GT struct

gt = rmfield_local(gt, 'fully_seg_frames');
gt = rmfield_local(gt, 'cents');
gt = rmfield_local(gt, 'info_seg');
gt = rmfield_local(gt, 'stats_seg');
gt = rmfield_local(gt, 'dataset');
gt = rmfield_local(gt, 'seq_num');

if isfield(gt_v1, 'border_width')
    gt = rmfield(gt, 'border_width');
    gt.foi_border = gt_v1.border_width;
else
    gt.foi_border = 0;
end
gt.seg.stats  = gt_v1.stats_seg';
gt.seg.info   = gt_v1.info_seg;
gt.seg.info(:,2) = 0;
gt.seg.info(:,3) = 0;

if isfield(gt_v1, 'stats_tra')
    t_list      = gt.seg.info(:,1);
    seg_counts  = cell2mat(arrayfun(@(x) sum([x{1}.Area]>0), gt_v1.stats_seg, 'UniformOutput', false));
    tra_counts  = cell2mat(arrayfun(@(x) sum([x{1}.Area]>0), gt_v1.stats_tra(t_list), 'UniformOutput', false));
    ratio       = seg_counts./tra_counts;
    %         if strcmp(dataset_name, 'PhC-C2DH-U373')
    %             tlist       = t_list(ratio >= 0.6)';
    %         else
    tlist       = t_list(ratio >= 0.8)';
    %         end
    gt.seg.info(ismember(gt.seg.info(:,1), tlist), 3) = 1;
else
    gt.seg.info(:,3) = 1;
end

gt.dim = 2;

if isfield(gt_v1, 'stats_tra') && isfield(gt_v1, 'info_tra')
    gt.tra.stats   = gt_v1.stats_tra';
    gt.tra.info    = gt_v1.info_tra;
    % %         gt.tra.info(:,5) = 0;
    gt.tra.tracked = gt_v1.tracking';
end
gt = rmfield_local(gt, 'info_tra');
gt = rmfield_local(gt, 'stats_tra');
gt = rmfield_local(gt, 'tracking');

gt.name= seq_name;
if isfield(gt, 'tra')
    for t=1:length(gt.tra.stats)
        gt.detect{t,1}     = bia.convert.centroids(gt.tra.stats{t});
    end
else
    for t=1:length(gt_v1.stats_seg)
        gt.detect{t,1}     = bia.convert.centroids(gt_v1.stats_seg{t});
    end
end
end

function st = rmfield_local(st, fn)
if isfield(st, fn)
    st = rmfield(st, fn);
end
end