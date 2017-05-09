function save_net(net, net_file)
% saves the network structure to caffe prototxt files
% 
% Inputs:
%     net       : network to be saved
%     net_file  : path of file in which the network will be saved
%

num_layers  = length(net.layers);
% Create caffe prototxt files
dat = [];
vname=@(x) inputname(1);
for i = 1:num_layers
    layer       = net.layers{i};
    % set names of top layers
    if sum(strcmp(layer.type, {'Crop','Pooling', 'LRN', 'Deconvolution', 'Convolution', 'Reshape', 'Accuarcy', 'CpnSmoothL1Loss', 'SmoothL1Loss', 'Accuracy', 'Softmax', 'InnerProduct'}))% top layer is same as the current layer
        layer.top           = layer.name;
        net.layers{i}.top   = layer.name;
    elseif sum(strcmp(layer.type, {'ReLU', 'Dropout'}))% top layer is same as bottom layer
        layer.top           = layer.bottom;
        net.layers{i}.top   = layer.bottom;
    end
    % for all layers except inputs set the top & bottom layer names
    if ~sum(strcmp(layer.type, {'input', 'first', 'name'}))
        str = sprintf('layer {\n\tname: "%s"\n\ttype: "%s"\n\ttop: "%s"\n', layer.name, layer.type, layer.top);
        if ~iscell(layer.bottom)
            str = sprintf('%s\tbottom: "%s"\n', str, layer.bottom);
        else
            for b=1:length(layer.bottom)
                str = sprintf('%s\tbottom: "%s"\n', str, layer.bottom{b});
            end
        end
    end
    if sum(strcmp(layer.type, {'first','name'}))
        str = sprintf('name: "%s"\n\n', layer.name);
    elseif sum(strcmp(layer.type, {'input'}))
        str = sprintf('input: "%s"\ninput_dim: %d\ninput_dim: %d\ninput_dim: %d\ninput_dim: %d\n\n', layer.name, layer.dim(1), layer.dim(2), layer.dim(3), layer.dim(4));
    else
        str = print_d(layer, vname(layer), 0);
        str = sprintf('%s\n', str);
    end
    %       include {
    %     phase: TRAIN
    %   }
    
    dat = [dat, str];
    %     disp(str2)
end
% save the network in file
fileID = fopen(net_file, 'w+');
fprintf(fileID, '%s', dat);
fclose(fileID);
% fprintf('Network saved: %s\n', net_file);
end

function str = print_d(layer, parent, tabs)
% convert the network layer to text (in format of caffe prototxts)
% 
names   = fieldnames(layer); % get field names within a struct
tabs    = tabs+1;% how many tabs to add to a line

if strcmp(parent, 'param2')
    parent = 'param';
end

str     = sprintf('%s {\n', parent);
for i=1:length(names)
    str = sprintf('%s%s', str, repmat(sprintf('\t'), 1, tabs));
    if isstruct(layer.(names{i}))
        str = sprintf('%s%s', str, print_d(layer.(names{i}), names{i}, tabs));
    else
        a = layer.(names{i});
        if isnumeric(a)
            % handles dim values
            c_name = names{i};
            if sum(strcmp(names{i}, {'dim1', 'dim2', 'dim3'}))
                c_name = 'dim';
            end
            str = sprintf('%s%s: %s\n', str, c_name, bia.utils.num2str(a));
        elseif iscell(a)
            for k=1:length(a)
                str = sprintf('%s%s%s: "%s"\n', str, repmat(sprintf('\t'), 1, tabs*(k>1)), names{i}, a{k});
            end
        else
            % some strings do not have commas, this if handles them
            if sum(strcmp(a, {'MAX', 'WITHIN_CHANNEL', 'true', 'false', 'SUM', 'TEST','TRAIN'}))
                str = sprintf('%s%s: %s\n', str, names{i}, a);
            else
                str = sprintf('%s%s: "%s"\n', str, names{i}, a);
            end
        end
    end
end
str = sprintf('%s%s}\n', str, repmat(sprintf('\t'), 1, tabs-1));%
end