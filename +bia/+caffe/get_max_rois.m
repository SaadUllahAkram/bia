function num_rois = get_max_rois(net)
% [mdl_sz, memory_needed] = bia.caffe.print_sz(cpn_net, struct('verbose',0));
% fprintf('%1.2f : %1.2f\n', mdl_sz, memory_needed)
[mdl_sz, memory_needed] = bia.caffe.print_sz(net, struct('verbose',0));

gpu_data = gpuDevice;
memory_left = round(gpu_data.AvailableMemory/1024/1024);% in MBs

if 6*memory_needed < memory_left
    num_rois = 3000;
elseif 5*memory_needed < memory_left
    num_rois = 1000;
elseif 4*memory_needed < memory_left
    num_rois = 500;
elseif 3*memory_needed < memory_left
    num_rois = 100;
    bia.print.fprintf('*red', sprintf('Using only %d rois\n', num_rois))
else
    num_rois = 100;
    error('Not enough memory: Net needs (more than): %1.2f, Available memory: %1.1f\n', memory_needed, memory_left)
end
% fprintf('%1.2f : %1.2f\n', mdl_sz, memory_needed)

end