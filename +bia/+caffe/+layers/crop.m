function [layer, name] = crop(name, bottom, axis, offset)
% Creates caffe crop layer
% 
% http://caffe.berkeleyvision.org/tutorial/layers/crop.html
% http://stackoverflow.com/questions/38588943/caffe-fully-convolutional-cnn-how-to-use-the-crop-parameters
% 
% Inputs:
%     name: str-> name of the layer (top blob has this name)
%     bottom: 2x1 cell array of strings. 1st entry is the layer to be cropped, 2nd entry provides the size after cropping.
%     offset: either a scalar, specifying how much offset to take from each cropped dimension. [default is 0]
%             or an array of size [4 - axis] (not implemented)
%     axis : from which dimension to start cropping. [deafult is '2', i.e. Only spatial dimensions (W&H) will be cropped]
% 
% ToDo: allow multiple different offsets


layer = struct('name',name,'type','Crop','bottom',{bottom},'top',name);

if nargin > 2
    if nargin < 4
        offset = 0;
    end
    layer.crop_param = struct('axis', axis, 'offset', offset);
end

end