function export(func_names, out_dirs, path_relative_tos, skip_dirs)
% Exports the needed files to run a function to a single folder
%
% Inputs:
%     func_names: cell array of function to be exported OR string containing func name 'demo.m'
%       out_dir and path_relative_to are linked, with each entry in both these variables specifying the new relative path for a file
%     out_dir           : full path where needed files will be copied to
%     path_relative_to  : path relative to this dir is created in out dir
% 
%     skip_dirs: cell array of dirs files from which will not be copied
% 

dry = 0;% 1: just shows what files will be copied or skipped, no file is copied
if ~iscell(func_names)
    a{1} = func_names;
    func_names = a;
    clear a;
end

if nargin < 3
    single_dir = 1;
else
    single_dir = 0;
end
if nargin < 4
    skip_dirs = cell(0,0);
end

for i=1:length(func_names)
    [fList, ~] = matlab.codetools.requiredFilesAndProducts(func_names{i});
    fList = fList';
    for j=1:length(fList)
        [f_dir, f_name, f_ext] = fileparts(fList{j});
        if strcmp(f_ext, '.mexa64')
            fprintf('Skipped: %s\n', fList{j})
            continue
        end
        skip = 0;
        for u=1:length(skip_dirs)
            if ~isempty(strfind(f_dir, skip_dirs{u}))
                skip = 1;
                break;
            end
        end
        if skip
            fprintf('Skipped: %s\n', fList{j})
            continue
        end
        if single_dir
            new_path = fullfile(out_dirs{1}, [f_name, f_ext]);
            fprintf('1 dir: Copied: %s\n->%s\n', fList{j}, new_path)
            if ~dry
                copyfile(fList{j}, new_path)
            end
        else
            f_dir_relative = '';
            for u=1:length(path_relative_tos)
                if ~isempty(strfind(f_dir, path_relative_tos{u}))
                    f_dir_relative = strrep(f_dir, [path_relative_tos{u}, filesep], '');
                    out_dir        = out_dirs{u};
                    break;
                end
            end
            if isempty(f_dir_relative)% path did not match with ones specified
                
                continue
            end
            if ~dry
                mkdir(fullfile(out_dir, f_dir_relative))
            end
            new_path = fullfile(out_dir, f_dir_relative, [f_name, f_ext]);
            if ~exist(new_path, 'file')
                fprintf('same dir tree: Copied: %s\n->%s\n', fList{j}, new_path)
                if ~dry
                    copyfile(fList{j}, new_path)
                end
            else
                fprintf('same dir tree: Exists: %s\n', new_path)
            end
        end
    end
end

end