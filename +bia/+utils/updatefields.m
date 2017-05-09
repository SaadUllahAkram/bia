function new = updatefields(default, new)
% Updates the structure "default" with values from "new".
% 
% Inputs:
%     default : structure with default values
%     new : structure with new values
% Outputs:
%     default : structure after its fields have been updated
%     

if isempty(new)
    new = default;
    return
end
fn = fieldnames(new);
for i=1:length(fn)
    if isstruct(new.(fn{i})) && isfield(default, fn{i}) && isstruct(default.(fn{i}))
        new.(fn{i}) = bia.utils.catstruct(default.(fn{i}), new.(fn{i}));
    end
end

new = bia.utils.catstruct(default, new);
end