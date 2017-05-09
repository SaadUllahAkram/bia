function [layer, name] = input(name, sz, phase)
% Creates caffe input layer
% http://caffe.berkeleyvision.org/tutorial/layers/input.html
% 
% Inputs:
%     name: str-> name of the layer (top blob has this name)
%     sz: 1x4 array of input size [batch_id, channel, W, H].
% 
% W & H can alter for images
% 

layer = struct('type','input','name',name,'dim',sz);
if nargin > 2
   layer.phase = phase;% 'train', 'test' 
end
end