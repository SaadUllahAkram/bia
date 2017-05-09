function clear(verbose)
% Clear loaded caffe models & solvers
if nargin == 0
   verbose = 0; 
end
if verbose == 1
   gpu_props = gpuDevice;
   mem_before = gpu_props.AvailableMemory;
end
tmp=evalc('caffe.reset_all()');

if verbose == 1
   gpu_props = gpuDevice;
   mem_after = gpu_props.AvailableMemory;
   fprintf('Net was using: %1.2fMBs\n', (mem_after - mem_before)/1024/1024)
end

end