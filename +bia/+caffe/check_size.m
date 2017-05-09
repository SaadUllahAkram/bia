function in = check_size(model, in, verbose)
if nargin == 1
    in  = 600;% input image size
end
if nargin < 3
    verbose = 0;
end

if isfield(model, 'seg_train')
    net = model.seg_train.layers;
elseif isfield(model, 'cpn_train')
    net = model.cpn_train.layers;
else
    net = model.layers;
end

in_list = [];
for i=1:length(net)
    if strcmp(net{i}.type, 'Convolution')
        k = net{i}.convolution_param.kernel_size;
        p = net{i}.convolution_param.pad;
        s = net{i}.convolution_param.stride;
        in = ceil( (in+2*p-k)/s ) + 1;
        in_list = [in_list, in];
    elseif strcmp(net{i}.type, 'Pooling')
        k = net{i}.pooling_param.kernel_size;
        p = net{i}.pooling_param.pad;
        s = net{i}.pooling_param.stride;
        in = ceil( (in+2*p-k)/s ) + 1;
        in_list = [in_list, in];
    elseif strcmp(net{i}.type, 'Deconvolution')
        k = net{i}.pooling_param.kernel_size;
        p = net{i}.pooling_param.pad;
        s = net{i}.pooling_param.stride;
        in = (in-1)*s + k - 2*p;
        in_list = [in_list, in];
    end
end

if verbose
    disp(in_list)
end

end
