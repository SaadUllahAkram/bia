function x = row_vec(x)
% converts 'x' to a row vector

if isempty(x)
    x = [];
end
assert(size(x, 1)<= 1 || size(x, 2) <= 1, 'Only 1 dimension can be greater than "1"')
if size(x, 1) > size(x, 2)
    x = x';
end

