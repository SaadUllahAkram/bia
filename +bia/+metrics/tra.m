function [tra, counts, errors, detect_fine] = tra(res_stats, res_info, gt, opts)
% computes TRA score from ISBI Cell Traking Challenge
% 
% Inputs :
%     res_stats : [Tx1 cells of struct]  must have fields -> 'PixelIdxList', 'BoundingBox', 'Area'
%     res_info  : [ _x4] Read text file containing info about tracK start/end times and parents
%     gt : ground truth
% Outputs:
%     TRA: TRA Score
%     counts.{fn,fp,mitosis_fn,etc} : TRA score breakdown->error counts
%     errors.{} : error ids
%     detect_fine = Tx4 -> [FN, NS, FP, TP]
%

version = 1;% 2: new metric, verify that the metric has changed in feb.

if nargin < 4;    opts = [];    end
opts_default = struct('mitosis_t_tol',0,...
    'w', struct('fn', 10, 'ns', 5, 'fp', 1, 'ea', 1.5, 'ec', 1, 'ed2', 1, 'ed1', 0),... % weights of errors
    'use_end_frames',1,...
    'verbose_best', 0,...
    'use_ctc',0,'out_dir','','exe_path','');
opts = bia.utils.updatefields(opts_default, opts);

mitosis_t_tol = opts.mitosis_t_tol;%how many frames b4 or after gt mitosis event, a detected mitosis is considered TP.
use_end_frames= opts.use_end_frames;% consider cells entering/exiting in 1st/last frame for enter/exit evaluation
w = opts.w;
verbose_best = opts.verbose_best;

counts = struct('ec',0,'ea',0,'ed1',0,'ed2',0,...
    'fp',0,'fn',0, 'ns',0, 'tp',0, 'mitosis_f1',0, 'mitosis_recall',0, 'mitosis_precision',0, 'mitosis_tp',0, 'mitosis_fn',0, 'mitosis_fp',0);
errors = struct('fn',[],'ns',[],'fp',[],'ec',[],'ea',[],'ed1',[],'ed2',[],'mitosis_fn',[],'mitosis_fp',[],'exit_fn',[],'exit_fp',[],'enter_fn',[],'enter_fp',[]);
tp_mitosis= [];
ed2_list = [];

if ~isfield(gt, 'tra')
    detect_fine = zeros(length(res_stats),4);
    tra = -1;
    return 
end
gt_stats = gt.tra.stats;
gt_info  = gt.tra.info;
t_tracked = logical(gt.tra.tracked);
T = length(gt_stats);

detect_fine = zeros(T, 4); % count of TP, FP, FN, NS, at each 't'
count_gt_t = zeros(1,T);
count_gt_edges_t = zeros(1,T);

%% get events evaluations
[gt_parent_ids, gt_parent_t, gt_exit_ids, gt_exit_t]     = bia.track.events(struct('use_end_frames',use_end_frames),gt_info);
[res_parent_ids, res_parent_t, res_exit_ids, res_exit_t] = bia.track.events(struct('use_end_frames',use_end_frames),res_info);
res_parent_unmatched = true(size(res_parent_ids));
% edges: [from_t, to_t, from_id, to_id]
gt_edges = bia.track.dag(gt_info , gt_stats, t_tracked);
res_edges = bia.track.dag(res_info, res_stats, t_tracked);

%%
gt_track_ids = gt_info (:,1);

gt2res = cell(T,1);% get id of res which matched with gt id
res2gt = cell(T,1);% get id of gt which matched with res id
TP   = zeros(1,T);
for t=1:T
    if t_tracked(t) == 0
        continue
    end
    gt_active_track_ids_t = gt_track_ids ( gt_info (:,2) < t & gt_info (:,3) >= t);% prev. track ids which are active at 't'
    gt_stats_t  = gt_stats{t};
    res_stats_t = res_stats{t};
    overlaps = bia.utils.overlap_pixels(gt_stats_t, res_stats_t, 0.5);
    %% Node labelling
    gt_active  = find([gt_stats_t.Area ] > 0);
    res_active = find([res_stats_t.Area] > 0);
    
    gt2res{t} = cell(length(gt_stats_t), 1);% RES ids matched with each GT id
    res2gt{t} = cell(length(res_stats_t), 1);% GT ids matched with each RES id
    for i=gt_active
        gt2res{t}{i,1} = find(overlaps(i, :) > 0);
        if isempty(gt2res{t}{i,1}); errors.fn = [errors.fn; t, i];% id of GT object which is not detected
        else;   TP(t) = TP(t)+1;
        end
    end
    for i=res_active
        res2gt{t}{i,1} = find(overlaps(:, i) > 0);
        if isempty(res2gt{t}{i,1}); errors.fp = [errors.fp; t, i];%FP
        elseif length(res2gt{t}{i,1}) > 1; errors.ns = [errors.ns; t, i];% NS
        end
    end
    
    %% Event evaluation: Notused for computing 'TRA'
    for i = gt_parent_ids(gt_parent_t == t)
        if ismember(gt2res{t}{i}, res_parent_ids) % has a match
            res_p_t = res_parent_t(res_parent_ids == gt2res{t}{i});
            if t <= res_p_t+mitosis_t_tol && t >= res_p_t-mitosis_t_tol
                tp_mitosis = [tp_mitosis; t, i];%#ok<AGROW>
                res_parent_unmatched(res_parent_t == t & res_parent_ids == gt2res{t}{i}) = false;
            else;   errors.mitosis_fn = [errors.mitosis_fn; t,i];
            end
        else;   errors.mitosis_fn = [errors.mitosis_fn; t,i];
        end
    end
    for i = gt_exit_ids(gt_exit_t == t)
        if ismember(gt2res{t}{i}, res_exit_ids) % has a match
            if t == res_exit_t(res_exit_ids == gt2res{t}{i})
            end
        end
    end
    %% Edge counting
    count_gt_t(t) = length(gt_active);
    count_gt_edges_t(t)   = length(intersect(gt_active, gt_active_track_ids_t));
    % detect_fine(t, :) = [size(errors.fn(errors.fn(:,1)==t,2),1), size(errors.ns(errors.ns(:,1)==t,2),1), size(errors.fp(errors.fp(:,1)==t,2),1), TP(t)];
end
errors.mitosis_fp = [res_parent_t(res_parent_unmatched); res_parent_ids(res_parent_unmatched)]';

ec_list = [];
if ~isempty(res_edges)
    for i=1:size(errors.fp, 1)% edges connected to fp nodes
        t = errors.fp(i, 1);
        k = errors.fp(i, 2);
        rm_ed1 = (res_edges(:, 1) == t & res_edges(:, 3) == k) | (res_edges(:, 2) == t & res_edges(:, 4) == k);
        errors.ed1 = [errors.ed1; res_edges(rm_ed1, :)];
        res_edges(rm_ed1, :) = [];
        counts.ed1 = counts.ed1+sum(rm_ed1);
    end
    if version == 2
        for i=1:size(errors.ns, 1)% edges connected to ns nodes
            t = errors.ns(i, 1);
            k = errors.ns(i, 2);
            rm_ed1 = (res_edges(:, 1) == t & res_edges(:, 3) == k) | (res_edges(:, 2) == t & res_edges(:, 4) == k);
            errors.ed1 = [errors.ed1; res_edges(rm_ed1, :)];
            res_edges(rm_ed1, :) = [];
            counts.ed1 = counts.ed1+sum(rm_ed1);
        end
    end

    % remove ED2 & count EC (edge semantic changes) : FP edges which are not in GT
    parfor i=1:size(res_edges, 1)
        e  = res_edges(i, :);
        m  = res2gt{e(1)}{e(3)};
        n  = res2gt{e(2)}{e(4)};
        idx = find(gt_edges(:,1) == e(1) & gt_edges(:,2) == e(2))';
        matched = 0;
        for j=idx
            e2 = gt_edges(j,:);
            if bia.utils.iou_mex(e2(3), m) && bia.utils.iou_mex(e2(4), n)
                if ~(e2(3)==e2(4) && e(3)==e(4) || e2(3)~=e2(4) && e(3)~=e(4)); ec_list = [ec_list; i]; end
                matched = 1;    break;
            end
        end
        if matched == 0;    ed2_list = [ed2_list, i];   end% ids of edges to be deleted.
    end
    errors.ec = res_edges(ec_list, :);
    errors.ed2= res_edges(ed2_list, :);
end
res_edges(ed2_list, :) = [];
for i=1:size(gt_edges, 1) % count edges present only in gt
    e = gt_edges(i, :);
    m = gt2res{e(1)}{e(3)};
    n = gt2res{e(2)}{e(4)};
    matched = 0;
    if ~isempty(n) && ~isempty(m) % one GT object was not detected so a new edge has to be added
        e_res_t = res_edges(res_edges(:,1) == e(1) & res_edges(:,2) == e(2), :);
        for j=1:size(e_res_t, 1)
            if e_res_t(j,3)==m && e_res_t(j,4)==n
                if version == 2
                    res_edges(res_edges(:,1) == e_res_t(j,1) & res_edges(:,2) == e_res_t(j,2) & res_edges(:,3) == e_res_t(j,3) & res_edges(:,4) == e_res_t(j,4), :) = [];
                end
                matched = 1;
                break;
            end
        end
    end
    if matched == 0;    errors.ea = [errors.ea; e]; end
end
% compute final score
counts = bia.utils.setfields(counts, 'fn',size(errors.fn,1),...
    'ns', size(errors.ns,1),...
    'fp', size(errors.fp,1),...
    'tp', sum(TP),...
    'ea', size(errors.ea,1),...
    'ec', size(ec_list,1),...
    'ed2', length(ed2_list),...
    'n_gt_edges',sum(count_gt_edges_t) + sum(gt_info(:,4)>0),...% gt move edges + mitosis edges
    'n_gt',sum(count_gt_t),...% gt objects
    'mitosis_fn',size(errors.mitosis_fn,1),...
    'mitosis_fp',size(errors.mitosis_fp,1),...
    'mitosis_tp',size(tp_mitosis,1),...
    'mitosis_n_gt',length(gt_parent_ids),...
    'mitosis_n_res',length(res_parent_ids));
counts = bia.utils.setfields(counts, 'mitosis_recall', counts.mitosis_tp/counts.mitosis_n_gt, 'mitosis_precision', counts.mitosis_tp/counts.mitosis_n_res);
counts = bia.utils.setfields(counts, 'mitosis_f1', bia.metrics.f1score(counts.mitosis_recall, counts.mitosis_precision));

tra_e = w.fn*counts.n_gt + w.ea*counts.n_gt_edges;
tra_p = w.ns*counts.ns + w.fn*counts.fn + w.fp*counts.fp + w.ed1*counts.ed1 + w.ed2*counts.ed2 + w.ea*counts.ea + w.ec*counts.ec;
tra  = 1-min(tra_e, tra_p)/tra_e;
mota = 1-(counts.fn+counts.fp+log10(1+counts.ea+counts.ec))/counts.n_gt;% read and update computation: https://raw.githubusercontent.com/Videmo/pymot/master/papers/bernardin2008evaluating.pdf
counts = bia.utils.setfields(counts, 'tra', tra, 'tra_p', tra_p, 'tra_e', tra_e, 'mota', mota);

if verbose_best
    allTRA(tra_e, w, counts.ns, counts.fn, counts.fp, counts.ed1, counts.ed2, counts.ea, counts.ec);
end
end


function allTRA(tra_e, w, NS, FN, FP, ED1, ED2, EA, EC)
TRA_NS = 1-min(tra_e, 0*NS + w.fn*FN + w.fp*FP + w.ed1*ED1 + w.ed2*ED2 + w.ea*EA + w.ec*EC)/tra_e;
TRA_FN = 1-min(tra_e, w.ns*NS + 0*FN + w.fp*FP + w.ed1*ED1 + w.ed2*ED2 + w.ea*EA + w.ec*EC)/tra_e;
TRA_FP = 1-min(tra_e, w.ns*NS + w.fn*FN + 0*FP + w.ed1*ED1 + w.ed2*ED2 + w.ea*EA + w.ec*EC)/tra_e;
TRA_ED = 1-min(tra_e, w.ns*NS + w.fn*FN + w.fp*FP + w.ed1*ED1 + 0*ED2 + w.ea*EA + w.ec*EC)/tra_e;
TRA_EA = 1-min(tra_e, w.ns*NS + w.fn*FN + w.fp*FP + w.ed1*ED1 + w.ed2*ED2 + 0*EA + w.ec*EC)/tra_e;
TRA_EC = 1-min(tra_e, w.ns*NS + w.fn*FN + w.fp*FP + w.ed1*ED1 + w.ed2*ED2 + w.ea*EA + 0*EC)/tra_e;
TRA_SEG = 1-min(tra_e, 0*NS + 0*FN + w.fp*FP + w.ed1*ED1 + w.ed2*ED2 + w.ea*EA + w.ec*EC)/tra_e;
fprintf('TRA::SEG:%1.3f, NS:%1.3f, FN:%1.3f, FP:%1.3f, ED:%1.3f, EA:%1.3f, EC:%1.3f\n', TRA_SEG, TRA_NS, TRA_FN, TRA_FP, TRA_ED, TRA_EA, TRA_EC)
end