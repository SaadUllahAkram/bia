function layer = eltwise(name, bottom, operation)
% http://caffe.berkeleyvision.org/tutorial/layers/eltwise.html
layer = struct('top', name, 'name', name, 'bottom', {bottom}, 'type', 'Eltwise');
if nargin > 3
    layer.eltwise_param.operation = operation;% PROD, SUM
end
end