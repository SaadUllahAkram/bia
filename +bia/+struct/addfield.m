function st = addfield(st, fieldname, mat)
% ADDFIELD Adds a new field to the given structure
% 
% Inputs:
%     st : structure
%     fieldname: string containing the name of field to be added
% Outputs:
%     mat : matrix containing the data for the added field
% 

n       = size(mat, 1);
data    = num2cell(mat, 2);
[st(1:n).(fieldname)] = data{:};

end