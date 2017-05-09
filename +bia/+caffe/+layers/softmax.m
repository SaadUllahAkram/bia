function layer = softmax(name, bottom, phase)
layer = struct('name',name,'type','Softmax','bottom',bottom);

end