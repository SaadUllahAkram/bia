function mat = ssum(mat)
% computes sum of the provided matrix
sz = size(mat);
for i=1:length(sz)
    mat = sum(mat);
end
