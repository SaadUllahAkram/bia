function activate(caffe_version, gpu_id)
% activates caffe
%
% Inputs:
%     caffe_version: 'cpn', 'latest', 'faster_rcnn', 'mnc', 'rfcn', 'ta-fcn'
%     gpu_id (1-based indexing): -1 (selects gpu with largest free memory), else (selects the specified gpu)
%

paths = get_paths();% get path to 'matlab' dir in 'caffe'
use_gpu = true;

if nargin < 2
    gpu_id = -1;
end
if nargin < 1
    caffe_version = 'cpn';
end

if strcmp(caffe_version, 'cpn')
    caffe_dir = paths.caffe.cpn;
else
    caffe_dir = paths.caffe.(caffe_version);
end

if ~exist(caffe_dir, 'dir')
    error('caffe dir not found: %s', caffe_dir)
end

bia.print.fprintf('red','Activating caffe: %s\n', caffe_version)
if gpuDeviceCount == 0
    addpath(genpath(caffe_dir));
    caffe.set_mode_cpu();
else
    if gpu_id == -1
        gpu_id = auto_select_gpu;
    end
    addpath(genpath(caffe_dir));
    if use_gpu
        gpuDevice(gpu_id);
        caffe.set_mode_gpu();
        caffe.set_device(gpu_id-1);
    else
        caffe.set_mode_cpu();
    end
end
end


function gpu_id = auto_select_gpu()
% gpu_id = auto_select_gpu()
% Select the gpu which has the maximum free memory
% --------------------------------------------------------
% Faster R-CNN
% Copyright (c) 2015, Shaoqing Ren
% Licensed under The MIT License [see LICENSE for details]
% --------------------------------------------------------

% deselects all GPU devices
gpuDevice([]);

maxFreeMemory = 0;
for i = 1:gpuDeviceCount
    g = gpuDevice(i);
    freeMemory = g.FreeMemory();
    fprintf('GPU %d: free memory %d\n', i, freeMemory);
    if freeMemory > maxFreeMemory
        maxFreeMemory = freeMemory;
        gpu_id = i;
    end
end
fprintf('Use GPU %d\n', gpu_id);

% deselects all GPU devices
gpuDevice([]);
end
