function [layer, name] = pool(name, bottom, ker_sz, stride, type, pad)
% Creates caffe pooling layer
% http://caffe.berkeleyvision.org/tutorial/layers/pooling.html
% 

if nargin < 6 || isempty(pad)
    pad = 0;
end
if nargin < 5 || isempty(type)
    type = 'MAX';% MAX, AVE, or STOCHASTIC
end
if nargin < 4 || isempty(stride)
    stride = 2;
end
if nargin < 3 || isempty(ker_sz)
    ker_sz = 2;
end

opts_pool = struct('pool',type,'kernel_size',ker_sz,'stride',stride,'pad',pad);

layer = struct('name',name,'type','Pooling','bottom',bottom,'pooling_param',opts_pool);
end