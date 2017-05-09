function [stats, conflicts] = tree(stats, opts)
% Takes region segmentation proposals and arranges them in trees.
% 
% Inputs:
%     stats.{Area, PixelIdxList, BoundingBox, Centroid} : of proposal regions
% Outputs:
%     stats.{level, branches, parent, child} : stats arranged in tree form
%             adds a new field "level" [1,2, ...] which indicates how far along the tree a proposal is. level=1 -> top most proposal
%             and "branches" which indicates to which branches the proposal belongs
%             and "parent" and "child" fields. Lists immediate parents and daughters. Is (-1) in case of no parent or daughters
%     conflicts : a matric containing "1" in locations where region in row# conflicts with region in col#
% 

branch_child_iou= 0.6;% overlap threshold (NOT IOU) "int(A,B)/A > threshold" for a node "A" to be a child
conflict_type   = 1;% 1(binary), 2(IoU)
verbose         = 0;


areas           = [stats(:).Area];
[~, idx_sorted] = sort(areas, 'descend');

N               = length(stats);
branch          = cell(0,1);% list of nodes in each branch
branch_leaf     = [];% stores the id of the last node (with no children) of each branch
num_branches    = 1;% keeps track of num of branches


% create branches [include partial branches (i.e. a branch from root till each node (even if it is not a leaf node))]
for i = bia.utils.row_vec(idx_sorted) %1:N
    if num_branches == 1% 1st prop (largest area) is used to initialize first branch
        branch{num_branches}      = i;
    else
        [iou,~,~,op2] = overlap_pixels(stats(i), stats(branch_leaf), branch_child_iou);% returns IoU values only if "int(A,B)/A > 0.7"
        if max(iou) > 0% if there is a branch with "int(A,B)/A >0.7", then make "A" child of branch with highest IoU(A,B)
            % apend to an old branch , keep the old branch as well, as there can be multiple branches at that node
           [max_iou, parent_idx]    = max(iou);
           parent                   = branch_leaf(parent_idx);
           parent_branch_id         = find(branch_leaf == parent);
           if verbose
                fprintf('Region id:%d -> Max(int(A,B)/A):%1.2f -> IoU:%1.2f, Parent id:%d\n', i, max_iou, op2(parent_idx), parent)
           end           
           assert(branch{parent_branch_id}(end) == parent, 'Parent should match')
           
           branch{num_branches}     = [branch{parent_branch_id}, i];
        else% create new branch
            branch{num_branches}    = i;
        end
    end
    branch_leaf(num_branches)   = i;
    num_branches                = num_branches+1;
end


% get rid of branches which end in non-leaf nodes.
num_branches        = length(branch);

assert(num_branches == N)

branch_depths           = cellfun(@(x) length(x), branch);
[branch_depths, idx]    = sort(branch_depths);
branch                  = branch(idx);
max_branch_depth        = max(branch_depths);% max number of nodes in a branch

idx_del         = find_branches_wo_leaf_nodes(branch);
branch(idx_del) = [];

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
        if j == 1
            stats(cur_node).parent = -1;
        else
            stats(cur_node).parent = branch_sel(j-1);
        end
        if j == length(branch_sel)
            stats(cur_node).child   = -1;
        else
            stats(cur_node).child = [stats(cur_node).child, branch_sel(j+1)];
        end
    end
end


%% create conflict matrix: 
% 0 -> regions refered by row# and col# have no conflict
% 1 or IoU(r,c) -> regions refered by row# and col# conflict with each other
conflicts = zeros(length(stats));
if conflict_type == 1
    % uses tree itself to create binary conflict matrix
    for i=1:length(branch)
        branch_sel  = branch{i};
        for k=bia.utils.row_vec(branch_sel)
            conflicts(k, branch_sel) = 1;
        end
    end
elseif conflict_type == 2
    % uses tree itself to create conflict matrix (IoU values)
    for i=1:length(branch)
        branch_sel  = branch{i};
        branch_stats= stats(branch_sel);
        iou         = overlap_pixels(branch_stats, branch_stats);
        for j=1:length(branch_sel)
            conflicts(branch_sel(j), branch_sel) = iou(j, :);
        end
    end
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

do_verify           = 0;% uses slow code to verify that results are correct
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


if do_verify% should produce same result as code above, but is much slower
    branch_depths           = cellfun(@(x) length(x), branch);
    max_branch_depth        = max(branch_depths);
    branch_depth_first      = arrayfun(@(x) find(branch_depths==x,1),1:max_branch_depth);% idx of 1st branch that has depth [1 2 3 ...]
    idx_del_2               = false(1, num_branches);
    for i=1:num_branches
        branch_sel          = branch{i};
        if length(branch_sel) == max_branch_depth
            break
        end
        j_start             = branch_depth_first(length(branch_sel)+1);
        for j=j_start:length(branch)% check if the whole branch (all its nodes) are inside any another branch.
            common_nodes    = ismember(branch_sel, branch{j});
            if sum(common_nodes) == length(branch_sel)% delete branch if it is inside another branch
               idx_del_2(i)   = true;
               break
            end
        end
    end
    assert(isequal(idx_del_2, idx_del))
end
end