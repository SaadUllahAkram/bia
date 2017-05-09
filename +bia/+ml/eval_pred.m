function [acc, res] = eval_pred(gt, pred, str, verbose)
% computes accuracy of all classes individually
% -1 in GT is treated as unlabelled sample
% 
% Inputs:
%     str: string containing label, e.g. Train, Test, etc
%     gt: a column vector containing GT labels
%     pred: a column vector containing predicted labels
%     verbose: 1: print results
% Outputs:
%     acc: accuracy
%     res: [label, num_samples, accuracy]
%     

if nargin < 4
    verbose = 0;
end

if nargin < 3
    str = '';
end
% remove samples without GT
idx = gt == -1;
gt(idx) = [];
pred(idx) = [];

n_samples = length(gt);
n_correct= sum(pred == gt);
acc = n_correct/n_samples;

labels = sort(unique(gt), 'ascend');
n_labels = length(labels);
if verbose
    fprintf('%s:: Acc: %1.3f (%d), (cls : cls_accu, cls_samples)::', str, acc, n_samples)
end

res = zeros(n_labels, 3);
for i=1:n_labels
    lab = labels(i);
    n_i = sum(gt==lab);
    acc_i = sum(pred(gt == lab) == lab)/n_i;
    if verbose
        fprintf(' (%d: %1.3f, %d)', lab, acc_i, n_i)
    end
    res(i, :) = [lab, n_i, acc_i];
end
if verbose
    fprintf('\n')
end

end