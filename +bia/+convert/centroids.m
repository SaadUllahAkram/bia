function [out, idx] = centroids(in)
% convert to a centroid into different formats
% m :: matlab's format: [x (column), y(row)]
%
% Inputs:
%     in : stats of an image's regions
% Outputs:
%     out : centroids in a matrix, each row containing 1 centroid
%     idx : idx of regions in given stats which contained a region.
%     

if isempty(in)
    out = zeros(0,2);
    idx = [];
    return
end

if ~isfield(in, 'Centroid')
   out = zeros(0,2);
   idx = [];
   return
end
out  = [in(:).Centroid];
cols = length(in(1).Centroid);
out  = reshape(out, cols, [])';
% out = cell2mat(arrayfun(@(x) x.Centroid, in, 'UniformOutput', false));
if isempty(out)
    out = zeros(0,cols);
    idx = [];
    return
end
idx_del = isnan(out(:,1)) | isnan(out(:,2));
out(idx_del, :) = [];% remove invalid centroids

out = round(out);
idx = find(~idx_del);
end