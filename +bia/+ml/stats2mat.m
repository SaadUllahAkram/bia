function [feats_mat, labels_mat, map_mat] = stats2mat(stats, feat_field, label_field)
% converts features/labels from struct to matrices
% 
% Inputs:
%     stats: region stats
%     feat_field: field name containing features
%     label_field: field name containing labels
% Outputs:
%     feats_mat: features
%     labels_mat: labels
%     map_mat: mapping to get 'row #' in matrix region given region 'id/frame' -> [t, idx] in stats{t}(i) struct
% 

if nargin < 2;  feat_field = 'Features';    end
if nargin < 3;  label_field = 'Label';    end

T = length(stats);
if isfield(stats{1}, label_field)
    return_label = 1;
else
    return_label = 0;
    labels_mat   = [];
end
feats   = cell(T,1);
labels  = cell(T,1);
map     = cell(T,1);
for t=1:T
    feats{t,1} = reshape([stats{t}.(feat_field)], length(stats{t}(1).(feat_field)), [])';
    map{t,1}   = [t*ones(size(feats{t},1), 1), [find([stats{t}.Area] > 0)']];
    if return_label
        labels{t,1}= [stats{t}.(label_field)]';
    end
end
map_mat = cell2mat(map);
feats_mat = cell2mat(feats);
if return_label
    labels_mat= cell2mat(labels);
end

end