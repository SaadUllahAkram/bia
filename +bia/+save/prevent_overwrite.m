function file_path = prevent_overwrite(file_path)
% modifies the filename to avoid overwriting
% appends "-(id)" at the end of filename in case a file already exists
% 
% Inputs:
%     file_path: initial path of file to be saved
% Outputs:
%     file_path: path where file should be saved
%

if ~exist(file_path, 'file')
    return
end

[d,f,e] = fileparts(file_path);
list    = dir(d);
f_orig  = f;

k = 1;
while(1)
    fn = [f,e];
    file_path = fullfile(d, fn);
    if ~exist(file_path, 'file')
        break;
    end
    for i=1:length(list)
        if strcmp(fn, list(i).name)
            f = sprintf('%s-(%d)', f_orig, k);
            k = k+1;
            break
        end
    end
end

end