function [stats, constraints, w, conflicts, idx_del] = props_tree(opts, stats)
% takes segmentation proposals and arranges them in trees.
% 
% Inputs:
%     stats.{Area, PixelIdxList, BoundingBox, Centroid} : of proposal regions
% Outputs:
%     stats.{level, branches, parent, child} : stats arranged in tree form
%             adds a new field "level" [1,2, ...] which indicates how far along the tree a proposal is. level=1 -> top most proposal
%             and "branches" which indicates to which branches the proposal belongs
%             and "parent" and "child" fields. Lists immediate parents and daughters. Is (-1) in case of no parent or daughters
%     conflicts : a matric containing "1" in locations where region in row# conflicts with region in col#
%     constraints: each row contains a constraint, which has 1 in columns indicating which props conflict with each other.
% 

opts_default    = struct('in_tol', 0.2, 'iou_child',0.9,'version',0,'verbose',0);
opts            = bia.utils.updatefields(opts_default, opts);
version         = opts.version;% same version as segmentation_tree.m

in_tol          = opts.in_tol;% max % of pixels of a new props which can be inside an old (already added to the tree) prop.
iou_child       = opts.iou_child;% overlap threshold (NOT IOU) "int(A,B)/A > threshold" for a node "A" to be a child
verbose         = opts.verbose;

areas           = [stats(:).Area];
[~, idx_sorted] = sort(areas, 'descend');

branch          = cell(0,1);% list of nodes in each branch
tree_id         = zeros(0,1);% list of nodes in each branch
branch_leaf     = [];% stores the id of the last node (with no children) of each branch
num_branches    = 1;% keeps track of num of branches

if version == 2% use simple NMS
    N = length(stats);
    w = ones(N, 1);
    [~,~,c1, c2] = bia.utils.overlap_pixels(stats, stats, iou_child);
    c2 = c2 > in_tol;
    c1 = c1 > iou_child;
    %conflicts = c1 | c2 | c1';
    conflicts = c1 | c2 | c1' | c2';
    
    % get ILP constraints
    vals = [];
    for i=1:size(conflicts,1)
        idx = find(conflicts(i,:));
        idx = setdiff(idx, i);
        for j=1:length(idx)
            vals = [vals; i, idx(j)];
        end
    end
    constraints = false(size(vals,1), size(conflicts,1));
    for i=1:size(vals,1)
        constraints(i, vals(i,:)) = true;
    end
    
    idx_del = [];
    return
end

% create branches [include partial branches (i.e. a branch from root till each node (even if it is not a leaf node))]
idx_del = [];
for i = idx_sorted %1:N
    skip = 0;
    if num_branches == 1% 1st prop (largest area) is used to initialize first branch
        branch{num_branches}      = i;
        tree_id(num_branches)     = 1;
    else
        [iou, ~, iou_in, iou_2, iou_in_2] = bia.utils.overlap_pixels(stats(i), stats(branch_leaf), iou_child);
        % if there is a branch with "int(A,B)/A > iou_child", then make "A" child of branch with highest IoU(A,B)
        % apend to an old branch , keep the old branch as well, as there can be multiple branches at that node
        if max(iou) > 0
           [max_iou, parent_idx]    = max(iou);
           parent                   = branch_leaf(parent_idx);
           parent_branch_id         = find(branch_leaf == parent);
           
           if in_tol > 0
               d_in = branch_leaf(iou_in_2 > in_tol);
               same_branch = branch{parent_branch_id};
               d_in = setdiff(d_in, same_branch);
               if ~isempty(d_in)
                   idx_del = [idx_del, i];
                   skip = 1;
                   continue
               end
           end
           if verbose
                fprintf('Region id:%d -> Max(int(A,B)/A):%1.2f -> IoU:%1.2f, Parent id:%d\n', i, max_iou, iou_in(parent_idx), parent)
           end
           branch{num_branches}     = [branch{parent_branch_id}, i];
           tree_id(num_branches)    = tree_id(parent_branch_id);    
        elseif version~=0 && max(iou_2) > in_tol
            idx_del = [idx_del, i];
            skip = 1;
        else% create new branch
            branch{num_branches}    = i;
            tree_id(num_branches)   = max(tree_id) + 1;
        end
    end
    if skip == 0
        branch_leaf(num_branches) = i;
        num_branches              = num_branches+1;
    end
end

% get rid of branches which end in non-leaf nodes.
branch_depths           = cellfun(@(x) length(x), branch);
[branch_depths, idx]    = sort(branch_depths);
branch                  = branch(idx);
tree_id                 = tree_id(idx);
max_branch_depth        = max(branch_depths);% max number of nodes in a branch

branch_del         = find_branches_wo_leaf_nodes(branch);
branch(branch_del) = [];
tree_id(branch_del)= [];

if verbose
    fprintf('# branches: %d\n', length(branch))
end

% add to stats for each region: branch #, child, level, parent
level               = cell(max_branch_depth,1);
stats(1).branches   = [];
stats(1).child      = [];
for i=1:length(branch)
    branch_sel = branch{i};
    for j=1:length(branch_sel)
        cur_node  = branch_sel(j); % node to be added
        level{j}  = [level{j}, cur_node];

        stats(cur_node).branches    = [stats(cur_node).branches, i];
        stats(cur_node).level       = j;
        stats(cur_node).tree        = tree_id(i);
        if j == 1
            stats(cur_node).parent = -1;
        else
            stats(cur_node).parent = branch_sel(j-1);
        end
        if j == length(branch_sel)
            stats(cur_node).child   = -1;
        else
            stats(cur_node).child = unique([stats(cur_node).child, branch_sel(j+1)]);
        end
    end
end

% create 'w' matrix
w = zeros(length(stats),1);
for i=1:length(branch)
    branch_sel = branch{i};
    for j=1:length(branch_sel)
        cur_node  = branch_sel(j); % node to be added
        level{j}  = [level{j}, cur_node];
        if j == 1
            w(cur_node)             = 1;
        else
            par = branch_sel(j-1);
            par_w = w(par);
            child = stats(par).child;
            w(cur_node) = 1.*par_w*(1/length(child));
        end
    end
end

% create conflict matrix:
constraints = zeros(length(branch), length(stats));
for i=1:length(branch)
    constraints(i, branch{i}) = 1;
end
constraints(:, idx_del) = [];
w(idx_del) = [];
stats(idx_del) = [];

conflicts = zeros(length(stats), length(stats));
for i=1:length(stats)
    rows = find(constraints(:, i))';
    idx = [];
    for k=rows
        idx = [idx, find(constraints(k,:))];
    end
    idx = unique(idx);
    conflicts(i, idx) = 1;
end

end


function idx_del = find_branches_wo_leaf_nodes(branch)
% returns branch indices that are subset (all nodes/region are inside another branch) of another branch
% 
% Inputs:
%     branch : a cell array same size as number of regions. Each cell contains region ids that lead from tree root to a segmentation region
% Outputs:
%     idx_del : idx of branches that are subset of another branch
% 

num_branches        = length(branch);
idx_del             = true(1, num_branches);
% create matrix -> (branch#, region #) = 1(if region is in that branch), 0(if region is not in that branch)
mat                 = false(num_branches,num_branches);
for i=1:num_branches
    branch_sel          = branch{i};
    mat(i, branch_sel)  = true;
end
% find branch which are subset of other branches
for i=1:num_branches
    branch_sel          = branch{i};
    bids                = [1:i-1, i+1:num_branches];% branch ids, which are used for search
    for k = branch_sel
        bids    = bids(mat(bids, k));% remove branches which do not contain k-th region
        if isempty(bids)% if there is no other branch with all region, break and keep it
            idx_del(i) = false;
            break;
        end
    end
end
end