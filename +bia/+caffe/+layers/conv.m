function [layers, name] = conv(name, bottom, num_out, opts_conv, opts_init, add_relu, lr_mult, groups)
% creates caffe conv layer
% http://caffe.berkeleyvision.org/tutorial/layers/convolution.html
% 

%     num_out: # of filters
%     opts_conv: conv layer option
%         kernel_size: filter size
%         pad: padding
%         stride: stride
%     opts_init: struct specifying how to initialize conv layer
%         .type: 'msra', 'xavier', 'gaussian'
%         .std (if type is gaussian)
%     add_relu: adds relu layer at the end
%     l_rate: 1x4 weight and decay multipliers, useful for fine-tuning layers
% 
%     Outputs:
%         layers: a struct if only conv layer added OR 2x1 cell array of structs
%         name: name of top blob
% 


if nargin < 7 || isempty(lr_mult)
    clear lr_mult
    lr_mult(1:2) = [1 1];%learning rate and decay multipliers for the filters
    lr_mult(3:4) = [2 0];%learning rate and decay multipliers for the biases
end
if nargin < 6 || isempty(add_relu)
    add_relu = 0;
end
if nargin < 5 || isempty(opts_init)
    opts_init = struct('type','xavier');
end
if nargin < 4 || isempty(opts_conv)
    opts_conv = [];
end

opts_conv_default = struct('num_output',num_out,'kernel_size',3,'pad',0,'stride',1,...
    'weight_filler',opts_init,'bias_filler',struct('type','constant','value',0));
opts_conv = bia.utils.updatefields(opts_conv_default, opts_conv);

layer = struct('name',name,'type','Convolution','bottom',bottom,'convolution_param',opts_conv);
if nargin >= 8
    layer.convolution_param.group = groups;
end
layer.param  = struct('lr_mult',lr_mult(1),'decay_mult',lr_mult(2));
layer.param2 = struct('lr_mult',lr_mult(3),'decay_mult',lr_mult(4));% actual name is 'param'

if add_relu
    name_relu = ['relu_',name];
    layer_relu = struct('name',name_relu,'type','ReLU','bottom',name,'top',name_relu);% relu layer
    layers{1} = layer;
    layers(end+1,1) = {layer_relu};
else
    layers = layer;
end

end