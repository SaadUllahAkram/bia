function debug_values(file_path, print_same)
% compares results (or state at some breakpoint) from two different versions of code to ensure they are same.
% save results (state) from code1 and call this function from code2
% 
% Input:
%     file_path: mat file containing results from code1
%     print_same: also prints variables which are same
% 

if nargin == 1
    print_same = 0;
end

data = load(file_path);% read data from pc1
fields = fieldnames(data);
for i=1:length(fields)
    var = evalin('caller', fields{i});% get the variable from pc2
    if ~isequal(var, data.(fields{i}))
        if isequaln(var, data.(fields{i}))
            if print_same
                fprintf('Other than NaNs, ''%s'' are same\n', fields{i})
            end
        else
            fprintf('''%s'' are different', fields{i})
            if isnumeric(var)
                fprintf(':: %1.3f %% of %d are very dif\n', 100*bia.utils.ssum(abs(var-data.(fields{i}))>0.02)/numel(var), numel(var))
            else
                fprintf('\n')
            end
        end
    else
        if print_same
            fprintf('''%s'' are same\n', fields{i})
        end
    end
end

end