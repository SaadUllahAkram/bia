function [layer, name] = concat(name, bottom, axis)
% Creates caffe concat layer
% http://caffe.berkeleyvision.org/tutorial/layers/concat.html
% 
% Inputs:
%     name: str-> name of the layer (top blob has this name)
%     bottom: Nx1 cell array of strings. names of layers to be concatenated.
%     axis [default 1]: 0 for concatenation along num and 1 for channels.
% 

layer = struct('name',name,'type','Concat','bottom',{bottom},'top',name);

if nargin > 2
   layer.concat_param = struct('axis',axis);
end

end