function layer = reshape(name, bottom, sz)
% Create caffe reshape layer
% http://caffe.berkeleyvision.org/tutorial/layers/reshape.html
% 
%     sz: 1x4 array: size of each fimension after reshaping.
%         0: copy the dimension as it is in input
%        -1: (only 1 dimension can have this value) Infer the dim size from the blob size after fixing the other 3 dimensions
    
layer = struct('name',name,'type','Reshape','bottom',bottom,'top',name,...
    'reshape_param',struct('shape',struct('dim',sz(1),'dim1',sz(2),'dim2',sz(3),'dim3',sz(4))));
end