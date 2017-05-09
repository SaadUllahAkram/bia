% script demonstrating matcaffe (matlab interface of caffe) usage
% http://caffe.berkeleyvision.org/tutorial/interfaces.html
% 
% In case of classification: Class Labels have to be in Channel (2nd) dimension.
% pool: when no padding used, rounds upwards
% 
% Caffe Blobs:
% [Batch_id, Channel_id, Height, Width]
% blob dimensions for batches of image data are number N x channel K x height H x width W.
% Blob memory is row-major in layout, so the last/rightmost dimension changes fastest.
% For example, in a 4D blob, the value at index (n, k, h, w) is physically located at index ((n * K + k) * H + h) * W + w.
% https://github.com/BVLC/caffe/wiki/Development
%% Common methods
% NAMES:
% net.layer_names;% layer names
% net.blob_names;% blob names
% net.inputs;% names of input blobs
% net.outputs;% names of output blobs
%
% BLOBS/PARAMETERS
% net.blobs(blob_name).get_data();% read blobs
% net.get_output;% returns the blob which are not input to anything
% net.params(layer_name,1).get_data();% read layer parameters (weights)
% net.params(layer_name,2).get_data();% read layer parameters (biases)
% net.params(layer_name, 1).set_data(weights); % set layer parameters (weights)
% net.params(layer_name, 2).set_data(biases); % set layer parameters (biases)
% net.layers(layer_name).params(1).get_data(); % get layer parameters (weights)
% net.layers(layer_name).params(1).set_data(weights); % set layer parameters (weights)
% net.set_params_data;% to set net parameters
% 
% OTHER METHODS
% net.save('model_path.caffemodel');% save network
% layer_type = net.layers(layer_name).type;% get layer type
%%

opts = struct('gpu',true,...
    'verify',0,...% 1: save model data, 2: verify model data, 0: 
    'cpn',1);

if opts.gpu
    caffe.set_mode_gpu();
else
    caffe.set_mode_cpu();
end

paths = get_paths();
root = paths.temp;

bia.caffe.clear
path_net = fullfile(root, 'train.prototxt');
path_solver = fullfile(root, 'solver.prototxt');
path_caffe_log = fullfile(root, 'caffe_log');
path_weights = fullfile(root, 'caffe_model.caffe');

% im = imread('office_1.jpg');
im = imread('onion.png');

net = get_net();
solver = struct('net',path_net,'momentum',0.9,'weight_decay',0.0005,'base_lr',0.001,'lr_policy','step','gamma',0.1,'stepsize',1000, 'display',1,'max_iter',3,'snapshot',0);

bia.caffe.save_net(net, path_net)
bia.caffe.save_solver(solver, path_solver)

bia.caffe.check_solver(path_solver)
caffe.init_log(path_caffe_log);
cs = caffe.Solver(path_solver);

conf.paths.dir = root;
if opts.verify
    bia.caffe.replicate(opts.verify, 1, conf, cs.net, 0);
end
iter_ = cs.iter();
if opts.cpn
    caffe.set_random_seed(5);
    max_iter = cs.max_iter();
end

% im = randn(100, 199);
labels = single(im(:,:,1) > 0.5);
regress_target = randn(size(im(:,:,1)));
labels_weights = single( single(im(:,:,1)) + regress_target > 0.5 );
regress_weights = labels_weights;
% labels = single(permute(labels, [3 4 1 2]));
while iter_ < 3
    fprintf('######################## iter: %3d ########################\n', iter_)
    if opts.cpn
        cs.net.set_phase('train');
    end
    rois = [0 10 10 70 70];
    rois = permute(rois, [3, 4, 2, 1]);
    rois = single(rois);
    
    net_inputs = {single(im), labels, labels_weights, regress_target, regress_weights, rois};
    if opts.verify
        net_inputs = bia.caffe.replicate(opts.verify, 2, conf, cs.net, iter_, net_inputs);
    end
    cs.net.save(path_weights);
    
    % separate forward & backward passes
    cs.net.reshape_as_input(net_inputs);% changes blob sizes, needed when input (image, # of rois, etc) sizes vary
    % cs.net.set_input_data(net_inputs);% not needed when only forward pass is run as forward takes input directly
    iter1_ = cs.iter();
    out = cs.net.forward(net_inputs);
    rst_forward = cs.net.get_output();
    cs.net.backward(out);
    
    % combined forward & backward passes
    cs.net.copy_from(path_weights);
    cs.net.reshape_as_input(net_inputs);
    cs.net.set_input_data(net_inputs);
    cs.step(1);
    
    iter_ = cs.iter();
    rst_step = cs.net.get_output();
    
    if opts.verify
        bia.caffe.replicate(opts.verify, 3, conf, cs.net, iter_, net_inputs, rst_step);
    end
    assert(isequal(rst_step, rst_forward) == 1)
    
    read_blobs(cs.net, 1);% read inputs
    read_blobs(cs.net, 2);% read all blobs
    read_blobs(cs.net, 3);% read outputs
    
    blob = cs.net.blobs('roip1').get_data();
    imshow(uint8(blob),[])
end


function read_blobs(net, type)
if type == 1
    blobs = net.inputs;
    fprintf('Inputs ::\n')
elseif type == 2
    blobs = net.blob_names;
    fprintf('Blobs ::\n')
elseif type == 3
    blobs = net.outputs;
    fprintf('Outputs ::\n')
end
for i=1:length(blobs)
    data = net.blobs(blobs{i}).get_data();
    sz = size(data);
    sz = [sz, -ones(1, 4-length(sz))];
    fprintf('%2d: %20s: [%4d %4d %4d %4d]\n', i, blobs{i}, sz(1), sz(2), sz(3), sz(4));
end
end


function net = get_net()
channels = 3;
W = 600;
H = 903;
N = W*H;

conv = @bia.caffe.layers.conv;
pool = @bia.caffe.layers.pool;
deconv = @bia.caffe.layers.deconv;
crop = @bia.caffe.layers.crop;
reshape = @bia.caffe.layers.reshape;
input = @bia.caffe.layers.input;
roi = @bia.caffe.layers.roi_pool;

net.layers = {};
net.layers{end+1,1} = bia.caffe.layers.name('test_net');
net.layers{end+1,1} = input('data',[1 channels W H]);
net.layers{end+1,1} = input('labels',[1 1 W H]);
net.layers{end+1,1} = input('labels_weights',[1 1 W H]);

net.layers{end+1,1} = input('regress_target',[1 1 W H]);
net.layers{end+1,1} = input('regress_weights',[1 1 W H]);


net.layers{end+1,1} = input('rois',[1 5 1 1]);
x=1;
net.layers(end+1:end+2,1) = conv('conv1','data',x,struct('pad',1),'',1);
net.layers{end+1,1} = pool('pool1','conv1',2,2);
net.layers{end+1,1} = deconv('up1','pool1',x,struct('group',x,'kernel_size',4,'pad',0,'stride',2));
net.layers{end+1,1} = crop('crop1',{'up1','conv1'});
net.layers(end+1:end+2,1) = conv('out','crop1',2,struct('pad',1),'',1);
net.layers(end+1:end+2,1) = conv('out1','crop1',1,struct('pad',1),'',1);
net.layers{end+1,1} = roi('roip1', 'data', 'rois', [60 60], 1);

net.layers{end+1,1} = reshape('rs_labels','labels',[1,1,1,-1]);
net.layers{end+1,1} = reshape('rs_labels_weights','labels_weights',[1,1,1,-1]);

net.layers{end+1,1} = reshape('rs_regress_target','labels',[1,1,1,-1]);
net.layers{end+1,1} = reshape('rs_regress_weights','labels_weights',[1,1,1,-1]);

net.layers{end+1,1} = reshape('rs_class','out',[1,2,1,-1]);

net.layers{end+1,1} = reshape('rs_score','out1',[1,1,1,-1]);
net.layers{end+1,1} = bia.caffe.layers.softmax_loss('loss_cls',{'rs_class','rs_labels', 'rs_labels_weights'});
net.layers{end+1,1} = bia.caffe.layers.smooth_l1loss('loss_reg',{'rs_score','rs_regress_target', 'rs_regress_weights'},1);
% net.layers{end+1,1} = bia.caffe.layers.accuracy('accu',{'rs_class','rs_labels'});
end