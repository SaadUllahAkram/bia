function imc = merge_imc(varargin)
% merge imc cell arrays
imc = cell(0);
N   = length(varargin);
for i=1:N
   imc(end+1 : end+length(varargin{i}), 1) = varargin{i};
end
end