function f_list = dependencies(fun_name, exlude_dirs, sort_by)
% finds and prints the list of functions necessary for execution of the calling/input function.  
%
% Inputs:
%     fun_name : function name as a string
%     exlude_dirs: cell array containing paths which will not be displayed
%     sort_by: '#files' (default), 'path'
% Outputs:
%     f_list : list of necessary functions (.m, .mexa64)
% 
    

if nargin == 0
    st = dbstack;% get the list of calling functions
    fun_name = which(st(2).file); % complete path of calling/parent function
end
if nargin < 2
    exlude_dirs = '';
end
if nargin < 3
    sort_by = '#files';
end
f_list = matlab.codetools.requiredFilesAndProducts(fun_name);

% thisFunPath = which(mfilename);% Get this function

[pathstr, name, ext] = fileparts(fun_name);
fprintf('********************************\n%s has %d dependencies.\nIt is in folder: %s\n********************************\n', [name, ext], length(f_list)-2, pathstr);
[dirs, files, fexts] = count(f_list, sort_by);
for i=1:length(dirs)
    if ~isempty(exlude_dirs) && contains(dirs{i}, exlude_dirs)
        continue
    end
    bia.print.fprintf('blue','%s:', dirs{i});
    n = length(files{i});
    if n > 1
        fprintf('\n');
    end
    for j=1:n
        if ~strcmp(fexts{i}{j},'.m')
            bia.print.fprintf('red','\t%s%s\n', files{i}{j}, fexts{i}{j});
        else
            bia.print.fprintf('black','\t%s%s\n', files{i}{j}, fexts{i}{j});
        end
    end
end
end


function [dirs, files, fexts] = count(flist, sort_by)
dirs = cell(0);
files = cell(0);
fexts = cell(0);
counts = [];
for i=1:length(flist)
    [fdir, fname, fext] = fileparts(flist{i});
    found = find(strcmp(fdir, dirs));
    if isempty(found)
       dirs{end+1,1} = fdir;
       files{end+1,1}{1} = fname;
       fexts{end+1,1}{1} = fext;
       counts(end+1) = 1;
    else
       files{found,1}{end+1,1} = fname;
       fexts{found,1}{end+1,1} = fext;
       counts(found) = counts(found) + 1;
    end
end

if strcmp(sort_by, '#files')
    [~,idx] = sort(counts, 'descend');
elseif strcmp(sort_by, 'path')
    [~,idx] = sort(dirs);
end
dirs = dirs(idx);
files = files(idx);
fexts = fexts(idx);

end