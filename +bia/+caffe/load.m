function [model1, model2] = load(def1, weights1, def2, weights2)
% loads caffe models from .caffemodel files
% 
% Inputs:
%     def       : full path of network definition file
%     weights   : full path of file containing trained model weights
% 

if ~exist(def1, 'file')
    error('caffe net not found: %s', def1)
end
if ~exist(weights1, 'file')
    error('caffe weights not found: %s', weights1)
end

model1 = caffe.Net(def1, 'test');% network for testing
model1.copy_from(weights1);

if nargin == 4
    if ~exist(def2, 'file')
        error('caffe net not found: %s', def2)
    end
    if ~exist(weights2, 'file')
        error('caffe weights not found: %s', weights2)
    end

    model2 = caffe.Net(def2, 'test');% network for testing
    model2.copy_from(weights2);
else
    model2 = [];
end

end
