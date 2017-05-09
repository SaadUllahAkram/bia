function [mdl_sz, memory_needed] = print_sz(net, opts)
% caffe uses 32 bit numbers
% Inputs:
%	net: loaded caffe network
% 
% http://stackoverflow.com/questions/40974695/caffe-memory-required-how-to-calculate

if nargin < 2
    opts = [];
end
opts_default = struct('blobs',1,'layers',1,'layer_types',{{'Convolution','Deconvolution','InnerProduct'}},...
    'blob_types',{{'Convolution','Deconvolution','InnerProduct','Crop','Concat','Eltwise'}},...
    'verbose',1);
opts = bia.utils.updatefields(opts_default, opts);
blob_types = opts.blob_types;
layer_types = opts.layer_types;
verbose = opts.verbose;

if opts.layers
    if verbose
        fprintf('Layers:\n')
    end
    mdl_sz = print_paras(net, layer_types, verbose);
end

if opts.blobs
    if verbose
        fprintf('Blobs:\n')
    end
    memory_needed = print_blobs(net, blob_types, verbose);
end

end


function mdl_sz = print_paras(net, identifiers, verbose)
names = net.layer_names;
mdl_sz = 0;
for i = 1:length(names)
    layer_type = net.layers(names{i}).type;
    if ismember(layer_type, identifiers)
        paras = net.params(names{i},1).get_data();
        sz = size(paras);
        sz = [sz, ones(1, 4-length(sz))];
        if verbose
            fprintf('%10s: sz: [%4d %4d %4d %4d], #para:%8d, paras(MBs): %3.3f\n', names{i}, sz(1), sz(2), sz(3), sz(4), numel(paras), 4*numel(paras)/1024/1024)
        end
        
        mdl_sz = mdl_sz + numel(paras);
    end
end
mdl_sz = 4*mdl_sz/1024/1024;
if verbose
    fprintf('Model size in MBs: %1.2f\n', mdl_sz)
end
end


function memory_needed = print_blobs(net, identifiers, verbose)
names = net.blob_names;
layers = net.layer_names;
memory_needed = 0;
for i = 1:length(names)
    if ismember(names{i}, layers)
        layer_type = net.layers(names{i}).type;
        if ismember(layer_type, identifiers)
            blob = net.blobs(names{i}).get_data();
            sz = size(blob);
            sz = [sz, ones(1, 4-length(sz))];
            if verbose
                fprintf('%10s: sz: [%4d %4d %4d %4d], size(MBs):%3.3f\n', names{i}, sz(1), sz(2), sz(3), sz(4), 4*numel(blob)/1024/1024)
            end
            memory_needed = memory_needed + 4*numel(blob)/1024/1024;
        end
    end
end
if verbose
    fprintf('Blobs require memory in MBs (Actual usage can be > 2x): %1.2f\n', memory_needed)
end
end