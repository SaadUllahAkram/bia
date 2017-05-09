function layer = name(name)
% Assigns a name to a caffe network

layer = struct('type','name','name',name);
end