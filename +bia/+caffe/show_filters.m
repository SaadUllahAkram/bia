function show_filters(mdl_path, mdl_prototxt, n_filters)
% displays learnt filters
% 
% Usage: 
%     show_filter(test_proto, weight_file)
%     show_filter(caffe_net)
% 
if nargin < 3
    n_filters = 16;
end
if ischar(mdl_path) && ischar(mdl_prototxt)
    net = cpn_load_model(mdl_prototxt, mdl_path);
elseif isa(mdl_path,'caffe.Net')
    net = mdl_path;
end

bia.caffe.print_sz(net)

conv_layers = get_layers(net);
n_convs = length(conv_layers);
[~, hax] = bia.plot.fig('Learnt Filters', [n_convs n_filters],1,1);
for i=1:n_convs
    paras = net.layers(conv_layers{i}).params(1).get_data();
    sz = size(paras);
    sz = [sz, ones(4-numel(sz), 1)];
    mu_abs = mean(abs(paras(:)));
    sigma = std(paras(:));
    sum_abs = sum(abs(paras(:)));
    % wg = sum(abs(paras(:)) > abs(mu) + 3*sigma)/numel(paras);
    fprintf('%10s: sz: [%4d %4d %4d %4d], #para:%8d, mu(std): %1.3f (%1.3f), sum: %1.3f\n', conv_layers{i}, sz(1), sz(2), sz(3), sz(4), numel(paras), mu_abs, sigma, sum_abs)
    nf = size(paras, 4);
    idx = randperm(nf, n_filters);
    for k=1:n_filters
        if k > sz(4)
            break;
        end
        % imshow(paras(:,:,1,idx(k)), [], 'parent', hax(i + n_convs*(k-1)))
        imshow(paras(:,:,1,idx(k)), [-3*sigma 3*sigma], 'parent', hax((i-1)*n_filters + k))
    end
    drawnow
end

end


function names = get_layers(net)
% find conv and up (deconv) layers
names = net.layer_names;
idx = [];
for i=1:length(names)
    layer_type = net.layers(names{i}).type;
    if ismember(layer_type, {'Convolution','Deconvolution'})
        idx = [idx;i];
    end
end
names = names(idx);
end