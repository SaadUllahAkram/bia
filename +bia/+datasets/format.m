function gt = format(ims, masks, markers, track_info, centroids, opts)
%
% Inputs:
%     ims: Tx1 cell array containing images
%     masks: Tx1 cell array containing segmentation masks
%     markers: Tx1 cell array containing marker masks
%     centroids: Tx1 cell array containing matrix of centroid positions. [x y z]
%     track_info: CTC tracking info
%     opts: dataset specific info
% Outputs:
%     gt: ground truth in a structured format
%
%

opts_default = struct('foi_border',-1,'name','unnamed','split',0,'detect','','dim',2,'fully_seg_ratio',1);
if nargin < 6
    opts = opts_default;
end
opts = bia.utils.updatefields(opts_default, opts);
fully_seg_ratio = opts.fully_seg_ratio;
detect = opts.detect; % 'tra': use tracking markers to obtain detection centroids, 'seg': use seg masks to obtain detection centroids
gt.foi_border = opts.foi_border;%how far away from border does foi (field of interest) start. -1: no border
gt.name = opts.name;% dataset name
gt.split = opts.split;% split/sequence id
gt.T = length(ims);% # images
gt.dim = opts.dim;% image dimension
%gt.sz = [size(ims{1},1), size(ims{1},2)];% size of images

do_seg = ~isempty(masks);
do_tra = ~isempty(markers);
do_det = 1*(~isempty(centroids)) + 2*(~isempty(markers) && strcmp(detect,'tra')) + 3*(~isempty(masks) && strcmp(detect,'seg'));

% .stats
% .info Xx5 [track_id track_start track_end parent_id left_or_died]. parent_id=0->no parent
% .tracked

gt.sz = zeros(gt.T, 3);
for t=1:gt.T
    gt.sz(t,:) = [size(ims{t},1) size(ims{t},2) size(ims{t},3)];
end

if do_tra
    n = length(markers);
    gt.tra.stats = cell(n, 1);
    gt.tra.info = track_info;
    gt.tra.tracked = arrayfun(@(x) ~isempty(x{1}), markers);
    for t=1:gt.T
        if ~isempty(markers{t})
            gt.tra.stats{t} = regionprops(markers{t}, 'Area','BoundingBox', 'Centroid', 'PixelIdxList');
        end
    end
    gt.tra.stats = fill_empty_stats(gt.tra.stats, 2);
    if sum(gt.tra.tracked) == 0
        gt = rmfield(gt, 'tra');
    end
end


if do_seg
    tlist = find(arrayfun(@(x) ~isempty(x{1}), masks));
    gt.seg.stats = cell(gt.T, 1);
    gt.seg.info = zeros(gt.T, 3);%[t, partially/fully seg, only fully seg]
    for t=1:gt.T
        gt.seg.info(t,:) = [t 0 0];
        if ismember(t, tlist)
            gt.seg.stats{t} = regionprops(masks{t}, 'Area','BoundingBox', 'Centroid', 'PixelIdxList');
            gt.seg.stats{t}([gt.seg.stats{t}.Area]==0) = [];%delete entries which were unused
            gt.seg.info(t,:) = [t 1 0];
        end
    end
    gt.seg.stats = fill_empty_stats(gt.seg.stats, 2);
    if sum(tlist) == 0
        gt = rmfield(gt, 'seg');
    end
end


if do_det == 1
    gt.detect = cell(gt.T, 1);
    for t=1:gt.T
        gt.detect{t} = centroids{t};
    end
elseif ismember(do_det, [2 3]) && (isfield(gt, 'tra') || isfield(gt, 'seg'))
    if do_det == 2 && isfield(gt, 'tra')
        detect_stats = gt.tra.stats;
    elseif do_det == 3 && isfield(gt, 'seg')
        tmp = gt.seg.stats;
        tmp_info = gt.seg.info;
        detect_stats = cell(gt.T,1);
        for t=1:gt.T
            if ismember(t, tmp_info(:,1))
                detect_stats{t} = tmp{tmp_info(:,1) == t};
            end
        end
    end
    gt.detect = cell(gt.T, 1);% centroid locations. Nx[2 or 3]
    for t=1:gt.T
        gt.detect{t} = bia.convert.centroids(detect_stats{t});
    end
end


if do_seg && do_tra && isfield(gt, 'tra') && isfield(gt, 'seg')
    seg_counts = cell2mat(arrayfun(@(x) sum([x{1}.Area]>0), gt.seg.stats, 'UniformOutput', false));
    tra_counts = cell2mat(arrayfun(@(x) sum([x{1}.Area]>0), gt.tra.stats, 'UniformOutput', false));
    ratios = seg_counts./tra_counts;
    fully_seg_t = ratios > fully_seg_ratio;
    gt.seg.info(fully_seg_t, 3) = 1;
elseif do_seg && isfield(gt, 'seg')
    gt.seg.info(:,3) = 1;
end
% gt.seg
% .stats
% .info : Xx3 [t slice_num fully segmented], slice_num=0->2d
end


function stats = fill_empty_stats(stats, dim)
for t=1:length(stats)
    if isempty(stats{t})
        stats{t}(1).Area = 0;
        stats{t}(1).PixelIdxList = [];
        stats{t}(1).Centroid = [NaN*ones(1, dim)];
        stats{t}(1).BoundingBox = [0.5*ones(1, dim), zeros(1, dim)];
    end
end
end