function s = keep_fields(s, fields)
% removes all fields except those specified
% 
% Inputs:
%     s: struct
%     fields: cell array containing fieldnames which should be kept
% Outputs:
%     s: struct
% 

fields_all = fieldnames(s);
for i=1:length(fields_all)
    if ~contains(fields_all{i}, fields)
        s = rmfield(s, fields_all{i});
    end
end

end