function gt = import_old_gt(dataset, scale, save_mat, use_ws)

if nargin < 4
    use_ws = 0;
end
if use_ws
    str_ws = '_WS';
else
    str_ws = '';
end

if nargin < 2
    scale = 1;
end

if nargin < 3
    save_mat = 0;
end

seq_num = str2double(dataset(end-1:end));
if isempty(seq_num) || isnan(seq_num)
    seq_num = [1,2];
elseif seq_num == 0
    seq_num = [1,2];
    dataset = dataset(1:end-3);
elseif seq_num > 0
    dataset = dataset(1:end-3);
end

for i = 1:length(seq_num)
    clearvars -except i dataset seq_num save_mat scale GT str_ws
    root = bia.datasets.paths(dataset, 'mat', 1);
    tmp = load(fullfile(root, sprintf('%s-%02d-GT%s.mat', dataset, seq_num(i), str_ws)));
    
    gt_v1 = tmp.gt;
    clear tmp
    gt_v2 = gt_v1;% gt_v2: version 2: of GT struct
    
    gt_v2 = rmfield_local(gt_v2, 'fully_seg_frames');
    gt_v2 = rmfield_local(gt_v2, 'cents');
    gt_v2 = rmfield_local(gt_v2, 'info_seg');
    gt_v2 = rmfield_local(gt_v2, 'stats_seg');
    gt_v2 = rmfield_local(gt_v2, 'dataset');
    gt_v2 = rmfield_local(gt_v2, 'seq_num');
    
    if isfield(gt_v1, 'border_width')
        gt_v2 = rmfield(gt_v2, 'border_width');
        gt_v2.foi_border = gt_v1.border_width;
    else
        gt_v2.foi_border = 0;
    end
    gt_v2.seg.stats  = gt_v1.stats_seg';
    gt_v2.seg.info   = gt_v1.info_seg;
    gt_v2.seg.info(:,2) = 0;
    gt_v2.seg.info(:,3) = 0;
    
    if isfield(gt_v1, 'stats_tra')
        t_list      = gt_v2.seg.info(:,1);
        seg_counts  = cell2mat(arrayfun(@(x) sum([x{1}.Area]>0), gt_v1.stats_seg, 'UniformOutput', false));
        tra_counts  = cell2mat(arrayfun(@(x) sum([x{1}.Area]>0), gt_v1.stats_tra(t_list), 'UniformOutput', false));
        ratio       = seg_counts./tra_counts;
%         if strcmp(dataset_name, 'PhC-C2DH-U373')
%             tlist       = t_list(ratio >= 0.6)';
%         else
            tlist       = t_list(ratio >= 0.8)';
%         end
        gt_v2.seg.info(ismember(gt_v2.seg.info(:,1), tlist), 3) = 1;
    else
        gt_v2.seg.info(:,3) = 1;
    end

    gt_v2.dim = 2;
    
    if isfield(gt_v1, 'stats_tra') && isfield(gt_v1, 'info_tra')
        gt_v2.tra.stats   = gt_v1.stats_tra';
        gt_v2.tra.info    = gt_v1.info_tra;
% %         gt_v2.tra.info(:,5) = 0;
        gt_v2.tra.tracked = gt_v1.tracking';
    end
    gt_v2 = rmfield_local(gt_v2, 'info_tra');
    gt_v2 = rmfield_local(gt_v2, 'stats_tra');
    gt_v2 = rmfield_local(gt_v2, 'tracking');
    
    gt_v2.name= sprintf('%s-%02d', dataset, seq_num(i));
    if isfield(gt_v2, 'tra')
        for t=1:length(gt_v2.tra.stats)
            gt_v2.detect{t,1}     = bia.convert.centroids(gt_v2.tra.stats{t});
        end
    else
        for t=1:length(gt_v1.stats_seg)
            gt_v2.detect{t,1}     = bia.convert.centroids(gt_v1.stats_seg{t});
        end
    end

    gt = gt_v2;
    root_export = bia.datasets.paths(dataset);
    if save_mat
        save(fullfile(root_export, sprintf('%s-%02d-GT.mat', dataset, seq_num(i))), 'gt')
    end
    GT{i} = gt;
end
gt = merge_gt(GT{:});
if scale ~= 1
    gt = resize_dataset(gt, [] ,scale);
end
end
function st = rmfield_local(st, fn)
if isfield(st, fn)
    st = rmfield(st, fn);
end
end