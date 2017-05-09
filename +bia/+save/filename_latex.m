function filename_latex(root, chars, ext)
% removes some chars (e.g. space) which may cause problem in names of figures in latex
% 
% Inputs:
%     root: full path of dir containing images
%     chars: cell array of chars to be removed
%     ext: extensions of files which will be renamed
%

if nargin < 3 || isempty(ext)
    ext = {'*.png', '*.jpg', '*.jpeg'};% file types which will be renamed
end
if nargin < 2 || isempty(chars)
    chars = {' ', '%', '#', '_'};% chars to be removed
end

if sum(strcmp(root(end), {'/','\'}))
    root = [root, filesep];
end

% get file list
n = length(ext);
list = cell(n,1);
for i=1:n
    list{i} = dir([root, ext{i}]);
end
list = cell2mat(list);

for i=1:length(list)
    file_in = fullfile(root, list(i).name);
    name_out = bia.utils.strreps(list(i).name, chars);
    file_out = fullfile(root, name_out);
    if ~strcmp(file_in, file_out)
        movefile(file_in, file_out)
    end
end
end
