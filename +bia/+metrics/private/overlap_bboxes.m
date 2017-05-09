function [ap, max_f1, rec, prec, errors] = overlap_bboxes(seg_res, gt, area_thresh, eval_type, top_x, verbose)
% eval_type : 1(bbox), 2(seg)

match_type  = 1; %1(greedy), 2(hungarian algo)
% default values
ap = 0;
max_f1 = 0;
rec = 0;
prec = 0;
errors = struct();

num_res     = sum(cellfun(@(x) sum([x(:).Area] > 0), seg_res));
if top_x == 0
    top_x = num_res;
end


if ~isfield(gt,'seg')% seg masks [gt boxes] are needed even for bb evaluation
    return
end
t_ful_seg = gt.seg.info(gt.seg.info(:,3)==1, 1);% get fully segmented frames
if isempty(t_ful_seg)
    return
end
rank        = [];
gt_map      = [];%[x y id t]
for k = 1:length(t_ful_seg)
    t           = t_ful_seg(k);
    idx_seg     = find(gt.seg.info(:,1)==t);
    seg_t       = seg_res{t};
    idx         = find([seg_t(:).Area] > 0)';
    scores      = [seg_t(idx).Score]';
    bb_t        = [bia.convert.bb(seg_t, 's2m'), scores];
    num_t       = length(scores);
    cents_t     = round(reshape([seg_t(idx).Centroid], 2, []))';

    gt_t_ids    = find([gt.seg.stats{idx_seg}.Area] > 0);
    num_gt      = length(gt_t_ids);
    gt_cents    = round(reshape([gt.seg.stats{idx_seg}(gt_t_ids).Centroid], 2, []))';
    gt_map      = [gt_map; gt_cents, gt_t_ids', t*ones(num_gt, 1)];
    if ismember(eval_type, [1,3])% bbox
        bb_gt       = bia.convert.bb(gt.seg.stats{idx_seg}, 's2m');
        o{k}.ol     = bboxOverlapRatio(bb_t(:,1:4), bb_gt);
    elseif ismember(eval_type, [2,4])% seg
        o{k}.ol     = bia.utils.overlap_pixels(seg_t, gt.seg.stats{idx_seg});
    end
    if match_type == 2
        o{k}.ol2    = 1-o{k}.ol;
        o{k}.ol2(o{k}.ol2>0.5) = Inf;
        o{k}.assignments = assignDetectionsToTracks(o{k}.ol2, 1);
    end
    o{k}.rank   = bb_t(:, 5);
    rank        = [rank; [1:num_t]', o{k}.rank, k*ones(num_t, 1), t*ones(num_t, 1), idx, cents_t];% [id, rank, t_idx, t, id_in_t_stats, x, y]
    jumps_gt(k) = num_gt;
end

num_gt      = sum(jumps_gt);
jumps_gt    = cumsum([0 jumps_gt]);
rank        = sortrows(rank, -2);

top_x       = min(top_x, size(rank, 1));
rank        = rank(1:top_x, :);
found       = zeros(size(rank,1), 1);
marked      = zeros(max(jumps_gt), 1);
marked_2    = zeros(max(jumps_gt), 1);

for j=1:size(rank, 1)
    k  = rank(j, 3);
    id = rank(j, 1);
    if match_type == 1
        [val, idx] = max(o{k}.ol(id,:));
        idx = idx+jumps_gt(k);
        marked_2(idx) = 1;
        if val > area_thresh && marked(idx) == 0
            marked(idx) = 1;
            found(j)    = 1;
        elseif val > area_thresh
            found(j)    = -1;% this cell has already been matched, so proposal is a duplicate
        end
    elseif match_type == 2
        idx = find(o{k}.assignments(:,2)==id, 1);
        if isempty(idx)
            found(j) = 0;
        else
            found(j) = 1;
        end
    end
end

num_dup             = sum(found==-1);% # proposals which are good but duplicates of another better proposal
found(found==-1)    = 0;

errors.fn           = gt_map(marked == 0, :);
errors.fp           = sortrows( rank(found ~= 1, [6 7 5 4]), [4 3]);

found               = cumsum(found);
rec                 = found/num_gt;
prec                = found./[1:length(found)]';


f1                  = 2*(rec.*prec)./(rec+prec);
max_f1              = max(f1);
num_fn_loose        = num_gt-sum(marked_2==1);% # gt which are outside all proposals
num_fn              = num_gt-sum(marked==1);% # gt for which no good proposal is found

if ~isempty(rec)
    ap = trapz(rec, prec);
end
if verbose
    fprintf('AP:%1.3f, Recall:%1.3f, F1-Score:%1.3f, #Props(#GT):%6d (%6d), Precision:%1.3f, FN:%6d, FN(outside all propos):%6d, Duplicates:%6d--#Props(#Used):%6d(%6d), IoU:%1.2f\n',...
        ap,rec(end),max_f1,num_res,num_gt,prec(end), num_fn, num_fn_loose, num_dup,size(bb_t,1),top_x,area_thresh);
end
end