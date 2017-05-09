function [layer, name] = deconv(name, bottom, num_out, opts_deconv, opts_init, lr_mult)
% kernel size should be 2x stride to upsample the image: https://github.com/shelhamer/fcn.berkeleyvision.org
% init_type = 1;% 1 gaussian, 2 (msra), 3(xavier)
% http://caffe.berkeleyvision.org/tutorial/layers/deconvolution.html

if nargin < 6 || isempty(lr_mult)
    lr_mult(1:2) = [1 1];%learning rate and decay multipliers for the filters
    lr_mult(3:4) = [2 0];%learning rate and decay multipliers for the biases
end
if nargin < 5 || isempty(opts_init)
    % this patch needed for bilinear initialization
    % https://github.com/BVLC/caffe/commit/805a995a8de3a4b50b9687c8140a277d265c32a0
    opts_init = struct('type','bilinear');
end
if nargin < 4
    opts_deconv = '';
end

opts_deconv_default = struct('num_output',num_out,'kernel_size',4,'pad',0,'stride',2,'group',1,...
    'weight_filler',opts_init,'bias_filler',struct('type','constant','value',0));
opts_deconv = bia.utils.updatefields(opts_deconv_default, opts_deconv);

layer = struct('name',name,'type','Deconvolution','bottom',bottom,'convolution_param',opts_deconv);
layer.param  = struct('lr_mult',lr_mult(1),'decay_mult',lr_mult(2));
layer.param2 = struct('lr_mult',lr_mult(3),'decay_mult',lr_mult(4));% actual name is 'param'
end