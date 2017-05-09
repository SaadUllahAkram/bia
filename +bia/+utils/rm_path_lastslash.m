function path = rm_path_lastslash(path)
% Removes the last slash in file/dir path

if strcmp(path(end), '\') || strcmp(path(end), '/')
    path = path(1:end-1);
end
