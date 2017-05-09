function str = strreps(str,a,b)
% replaces multiple strings in a given string in the order listed in second argument.
% if 'b' is not specified, strings in 'a' are replaced with empty string
% 
% Inputs:
% 	str : string
% 	a : cell array containing strings which have to be removed
% 	b (optional): cell array containing strings which will be inserted inplace of strings in 'a'
% 

if nargin < 3
    b = repmat({''},length(a),1);
end

for i=1:length(a)
   str = strrep(str, a{i}, b{i});
end
end
