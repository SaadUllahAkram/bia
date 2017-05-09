function [ap,recall,precision,errors,b,b1] = ap_edges(opts, gt, res_stats, edges_in)
% evaluates given proposal bboxes or segmentation masks using markers inside them criteria.
%     TP: If there is only 1 GT marker (not matched yet) inside the mask or bbox
%     FP: If there is 0 or 1+ GT marker inside the mask or bbox
% 
% Inputs:
% Outputs:
%     ap : area under the prec-rec curve
%     rec : recall values as proposals are evaluated in the order of their score (descending)
%     prec : precision values corresponding to rec values
% 

% edges: t1 id1 t2 id2 p
% gt_edges: t1 id1 id2 type

opts_default = struct('move',0,'mitosis',0,'ignore_dup',0,'verbose',0,'cost',1);
opts = bia.utils.updatefields(opts_default, opts);
ignore_dup = opts.ignore_dup;
verbose = opts.verbose;
cost = opts.cost;% 1: score field contains cost NOT prob., else: contains prob.

if opts.move;    keep_id = 1;
elseif opts.mitosis;    keep_id = 4;
end

T = gt.T;
gt_edges = get_edges(gt.tra.stats, gt.tra.info, keep_id);
t_tracked = find(gt.tra.tracked)';
overlaps = cell(T,1);
over = cell(length(t_tracked), 1);
if isstruct(edges_in)
    tracks = edges_in.tracks;
    edges_in = get_edges(tracks.stats, tracks.info);
    edges_in(edges_in(:,4) ~= keep_id, :) = [];
    edges_in = [edges_in(:,1:2) zeros(size(edges_in,1),1) edges_in(:,3:end)];
    parfor i=1:length(t_tracked)%1:T
        t = t_tracked(i);
        over{i} = bia.utils.overlap_pixels(gt.tra.stats{t}, tracks.stats{t}, 0.5);
    end
else
    parfor i=1:length(t_tracked)%1:T
        t = t_tracked(i);
        over{i} = bia.utils.overlap_pixels(gt.tra.stats{t}, res_stats{t}, 0.5);
    end
end
for i=1:length(t_tracked)
    t = t_tracked(i);
    overlaps{t,1} = over{i};
end


[~,map] = bia.convert.id(res_stats);
edges = bia.convert.id(edges_in(:,1),map);
tmp = bia.convert.id(edges_in(:,2),map);
if cost == 1
    edges(:,[3,4,5]) = [tmp(:,2), cost2prob(edges_in(:, 3)), 0*tmp(:,2)];
else
    edges(:,[3,4,5]) = [tmp(:,2), (edges_in(:, 3)), 0*tmp(:,2)];
end
edges = sortrows(edges, -4);

edges(~ismember(edges(:,1), t_tracked), :) = [];
for i=1:size(edges,1)
    % [t, id1, id2] = bia.utils.set(edges(i,1), edges(i,2), edges(i,3));
    t = edges(i,1);
    if sum(ismember([t t+1], t_tracked)) ~= 2
        edges(i,5) = -1;
        continue
    end
    
    id1 = edges(i,2);
    id2 = edges(i,3);
    if id1 == 0%enter
        [gt1, gt2] = bia.utils.set(0, find(overlaps{t}(:,id2)));%#ok<FNDSB>
    elseif id2 == 0%exit
        [gt1, gt2] = bia.utils.set(find(overlaps{t}(:,id1)), 0);%#ok<FNDSB>
    else% move/mitosis
        % [gt1, gt2] = bia.utils.set(find(overlaps{t}(:,id1)), find(overlaps{t+1}(:,id2)));%#ok<FNDSB>
        gt1 = find(overlaps{t}(:,id1));
        gt2 = find(overlaps{t+1}(:,id2));
    end

    if length(gt1) == 1 && length(gt2) == 1
        idx = find(gt_edges{t}(:,2) == gt1 & gt_edges{t}(:,3) == gt2);
        if ~isempty(idx)
            if sum(gt_edges{t}(idx, 5)) == 0
                edges(i,5) = 1;
                gt_edges{t}(idx, 5) = 1;
            else
                edges(i,5) = 2;
            end
        end
    else
        edges(i,5) = 3;% prop error
    end
end
gt_edges = cell2mat(gt_edges);

[b,b1] = bia.metrics.brier(edges);

if ignore_dup
   edges(edges(:,5) == 2,:) = [];
end

edges(edges(:,5) == -1,:) = [];% delete edge which are not being used
n_edges = size(edges,1);% result edges
n_gt = size(gt_edges, 1);% gt edges

tp = sum(edges(:,5)==1);% tp edges
tpp = sum(edges(:,5)==2);% duplicate edges
prop_e = sum(edges(:,5)==3);
fn = sum(gt_edges(:,5)==0);

found = cumsum(edges(:,5)==1);
recall = found/n_gt;
precision = found./[1:n_edges]';

ap = trapz(recall, precision);

errors.fn = gt_edges(gt_edges(:,5)==0, :);
if verbose
    fprintf('AP:%1.3f, GT:%d->TP:%d, FN:%d, Dup:%d, RES:%d, BadProps:%d\n', ap, n_gt, tp, fn, tpp, n_edges, prop_e)
end
end


function edges = get_edges(stats, info, keep_id)
% edges: [t, from, to, edge_type]
labels = struct('move',1,'enter',2,'exit',3,'mitosis',4);
[parents_id, parents_t, exit_id, exit_t, enter_id, enter_t] = bia.track.events(struct(''), info);

T = max(info(:,3));
edges_enter = cell(T,1);
edges_exit = cell(T,1);
edges_move = cell(T,1);
edges_mitosis = cell(T,1);
for t=1:T
   enter_ids = enter_id(enter_t==t);
   exit_ids = exit_id(exit_t==t);
   n_enter = length(enter_ids);
   n_exit = length(exit_ids);
   edges_enter{t} = zeros(n_enter, 5);
   edges_exit{t} = zeros(n_exit, 5);
   for i=1:n_enter
        edges_enter{t}(i,:) = [t 0 enter_ids(i) labels.enter 0];
   end
   for i=1:n_exit
        edges_exit{t}(i,:) = [t exit_ids(i) 0 labels.exit 0];
   end
   if t==T; continue; end
   
   active_t1 = find([stats{t}.Area]>0);
   active_t2 = find([stats{t+1}.Area]>0);
   move_ids = intersect(active_t1, active_t2);   
   n_move = length(move_ids);
   edges_move{t} = zeros(n_move, 5);
   for i=1:n_move
        edges_move{t}(i,:) = [t move_ids(i) move_ids(i) labels.move 0];
   end
   
   % daughters:
   parents_ids = parents_id(parents_t==t);
   edges_mitosis{t} = zeros(0, 5);
   for i=1:length(parents_ids)
       daus = info(ismember(info(:,4), parents_ids(i)),1);
       for j=1:length(daus)
            edges_mitosis{t}(end+1,:) = [t parents_ids(i) daus(j) labels.mitosis 0];
       end
   end
end


if nargin < 3
    edges = [cell2mat(edges_enter); cell2mat(edges_exit); cell2mat(edges_move); cell2mat(edges_mitosis)];
elseif keep_id == 1
    edges = edges_move;
elseif keep_id == 4
    edges = edges_mitosis;
end
end


function p = cost2prob(c)
% converts cost ~[-37 37] to prob. [0-1]
p = exp(-c)./(1+exp(-c));
end