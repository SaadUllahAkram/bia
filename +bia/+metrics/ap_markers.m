function [ap, max_f1, rec, prec, errors] = ap_markers(use_seg, seg_res, gt, verbose)
% evaluates given proposal bboxes or segmentation masks using markers inside them criteria.
%     TP: If there is only 1 GT marker (not matched yet) inside the mask or bbox
%     FP: If there is 0 or 1+ GT marker inside the mask or bbox
% 
% Inputs:
%     bb : [xmin ymin w h score t]
%     seg : "bb" and "seg" should be in same order
%     gt : ground truth structure
% Outputs:
%     ap : area under the prec-rec curve
%     max_f1 : max f1-score for all rec-prec combinations
%     rec : recall values as proposals are evaluated in the order of their score (descending)
%     prec : precision values corresponding to rec values
% 

% gt.{T, sz, detect}

if nargin < 4
    verbose = 1;
end

T = gt.T;

if ~isfield(gt, 'tra') && ~isfield(gt, 'seg') && ~isfield(gt, 'detect')
    ap = -1;
    max_f1 = -1;
    rec = -1;
    prec = -1;
    errors = struct('fn',0,'fp',0,'os',0);
    return
end
if isfield(gt, 'tra')
    t_tracked = find(gt.tra.tracked)';
    if isempty(t_tracked)
        t_tracked = 1:length(gt.seg.stats);
    end
elseif isfield(gt, 'seg')
    t_tracked = 1:length(gt.seg.stats);
end
for t = setdiff(1:T, t_tracked)
    seg_res{t} = [];
end
[seg, bb, map] = convert_res_old(seg_res);

gt_cents = [];
for t=1:T
    len = size(gt.detect{t},1);
    gt_cents(end+1:end+len, :) = [gt.detect{t}, [1:len]', t*ones(len,1)];% [x,y,id,t]
end

[bb, idx] = sortrows(bb, -5); % sort using 5th column in descending order
bb(:,1:4) = [bb(:, 1), bb(:, 2), bb(:, 1)+bb(:, 3), bb(:, 2)+bb(:, 4)];%[xmin ymin xmax ymax]

num_res     = size(bb, 1);
num_gt      = size(gt_cents, 1);

matched = zeros(1, num_gt);% 1: marker has been matched with a prop, 0: has not been matched so far
inside  = zeros(1, num_gt);% 1: marker was inside at least 1 prop, 0: has not been inside any prop so far
found   = zeros(1, num_res);% 1: matched with GT, -1: matched but was duplicate

gt_cents_idx_cell = cell(T,1);% mapping from cell to mat
gt_cents_cell     = cell(T,1);%[x y]
gt_ind_cell       = cell(T,1);% indices in image
for t=1:T % pre-processing to speed-up
    gt_cents_idx_cell{t} = find(gt_cents(:,4)==t);
    gt_cents_cell{t}     = gt_cents(gt_cents_idx_cell{t}, 1:2);% gt current 't' cents
    gt_ind_cell{t}       = sub2ind(gt.sz, gt_cents_cell{t}(:,2), gt_cents_cell{t}(:,1));% get 't' ind
end

if use_seg
    seg = seg(idx);
    map     = map(idx, :);
end

if use_seg% pre-compute 'in' for speed-up
    parfor i = 1:num_res
        t         = bb(i, 6);
        gt_ind_t  = gt_ind_cell{t};% gt current 't' cents
        in_cell{i}= ismember(gt_ind_t, seg(i).PixelIdxList);
    end
end

e_fp_bin = false(num_res,1);
for i = 1:num_res
    t           = bb(i, 6);
    b           = bb(i, 1:4);
    gt_idx_t    = gt_cents_idx_cell{t};
    if use_seg
        in = in_cell{i};
    else
        gt_cents_t  = gt_cents_cell{t};% gt current 't' cents
        in = b(1) <= gt_cents_t(:,1) & b(3) >= gt_cents_t(:,1) & b(2) <= gt_cents_t(:,2) & b(4) >= gt_cents_t(:,2);% finds which gt marker are inside the bbox
    end
    idx = gt_idx_t(in);% idx of GT marker inside the prop
    inside(idx)  = 1;
    if length(idx) == 1 && matched(idx) == 0% tp: only 1 marker inside && that marker has not been assigned already
        matched(idx) = 1;
        found(i) = 1;
    elseif sum(in) == 1% fp: duplicate
        found(i) = -1;
        e_fp_bin(i) = true;
    elseif sum(in) > 1 || sum(in) == 0% fp: bad proposal
        e_fp_bin(i) = true;
    end
end
e_fp = [reshape(round([seg(e_fp_bin).Centroid]), 2, [])', map(e_fp_bin, [2 1])];

% errors
% errors.fn = gt_cents(inside == 0, :);%[x y id t]% outside all props
errors.fn = gt_cents(matched == 0, :);%[x y id t]% not matched with a GT
errors.fp = sortrows(e_fp, [4 3]);%[x y id t]
% errors.fp = e_fp;%[x y id t]
errors.os = gt_cents(matched == 0 & inside ~= 0, :);%[x y id t]

%
num_dup         = sum(found==-1);% # proposals which are good but duplicates of another better proposal
found(found==-1)= 0;
found           = cumsum(found);
rec             = found/num_gt;
prec            = found./(1:length(found));
ap              = trapz(rec, prec);% area under prec-rec curve
f1score         = 2*(rec.*prec)./(rec+prec);
num_fn_loose    = num_gt-sum(inside==1);% # gt which are outside all proposals
num_fn          = num_gt-sum(matched==1);% # gt for which no good proposal is found
max_f1          = max(f1score);
if verbose
    fprintf('AP:%1.3f, Recall:%1.3f, F1-Score:%1.3f, #Props(#GT):%6d (%6d), Precision:%1.3f, FN:%6d, FN(outside all propos):%6d, Duplicates:%6d\n',ap,rec(end),max_f1,num_res,num_gt,...
        prec(end), num_fn, num_fn_loose, num_dup);
end
end