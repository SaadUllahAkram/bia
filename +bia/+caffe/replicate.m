function inputs = replicate(mode, action, conf, net, iter, inputs, outputs)
% mode = 1;
% cpn.dbg.replicate(mode, 1, conf, caffe_solver.net);
% net_inputs = cpn.dbg.replicate(mode, 2, conf, caffe_solver.net, iter_, net_inputs);
% cpn.dbg.replicate(mode, 3, conf, caffe_solver.net, iter_, net_inputs, rst);



% mode: 1
% action:
% 1: save initialization
% 2: save inputs
% 3: save outputs

% mode: 2
% action:
% 1: load initial model
% 2: load inputs
% 3: load outputs

if nargin < 6
    inputs = [];
end

if mode == 0
    return
end

dbg_dir = fullfile(conf.paths.dir, 'debug');
mdl_file = fullfile(dbg_dir, sprintf('%d.caffemodel', iter));
in_file = fullfile(dbg_dir, sprintf('in_%d.mat', iter));
out_file = fullfile(dbg_dir, sprintf('out_%d.mat', iter));
if mode == 1% save data
    bia.save.mkdir(dbg_dir)
    if action == 1
        net.save(mdl_file);
    elseif action == 2
        save(in_file, 'inputs')
    elseif action == 3
        save(out_file, 'outputs')
    end
    if iter > 0
        net.save(mdl_file);
    end
elseif mode == 2% verify data
    if action == 1
        net.copy_from(mdl_file);
    elseif action == 2
        load(in_file, 'inputs')
    elseif action == 3
        out = load(out_file, 'outputs');
        outputs_old = out.outputs;
        if ~(isequaln(outputs_old, outputs))
            warning('error 1')
        end
    end
    if iter > 0
        data_cur = read_w(net);
        net.copy_from(mdl_file);
        data_old = read_w(net);
        diff_weights(data_cur, data_old);
%         if ~(isequaln(data_cur, data_old))
%             warning('error')
%         end
    end
end

end


function diff_weights(a, b)
for i=1:length(a)
    s = bia.utils.ssum(abs(a(i).weights - b(i).weights));
    n = bia.utils.ssum(abs(a(i).weights));
    if s/n > 10^-3
        warning('Difference is large: %d', i)
    end
end
end


function data = read_w(net)
layer_types = {'Convolution', 'InnerProduct', 'Deconvolution'};
layers = net.layer_names;
data = struct('name',{},'type',{},'weights',{},'biases',{});
for i=1:length(layers)
    name = layers{i};
    type = net.layers(name).type;
    if contains(type, layer_types)
        weights = net.layers(name).params(1).get_data();
        biases = net.layers(name).params(2).get_data();
        data(end+1,1) = struct('name', name, 'type', type, 'weights', weights, 'biases', biases);
    end
end
end