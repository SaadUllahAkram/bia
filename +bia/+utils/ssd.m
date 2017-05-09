function c = ssd(a, b)
% computes ssd of provided matrices
if isempty(a) && isempty(b)
    c = 0;
    return
end
assert(numel(a)==numel(b), 'different size')
d = (a-b).^2;
c = bia.utils.ssum(d);
