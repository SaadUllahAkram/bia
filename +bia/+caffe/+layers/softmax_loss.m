function layer = softmax_loss(name, bottom, top, weight)
% Creates caffe softmax with multi-nomial logistic loss
% http://caffe.berkeleyvision.org/tutorial/layers/softmaxwithloss.html
% 
%     weight: weight of loss. Is only used for computing backward pass, i.e. Top blob value is not affected by this weight
% 
if nargin < 4
    weight = 1;
end
if nargin < 3 || isempty(top)
    top = name;
end
assert(iscell(bottom), 'softmax loss layer must have 2 or 3 bottom blobs')
assert(length(bottom) >= 2, 'softmax loss layer must have 2 or 3 bottom blobs')
layer = struct('name',name,'type','SoftmaxWithLoss','bottom',{bottom},'top',top,'loss_weight',weight,'loss_param', struct('normalize','true'));
end