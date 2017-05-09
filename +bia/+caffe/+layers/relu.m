function layer = relu(name)
layer = struct('name',sprintf('relu_%s',name),'type','ReLU','bottom',name,'top',name);
end