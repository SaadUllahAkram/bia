function onPath = in_path(folder)
% checks whether the provided folder is included in matlab's path or not
% 
% Inputs:
%     folder: path which will be checked
% Outputs:
%     onPath: 1(folder is in matlab's path), 0(folder is not in matlab's path)
%     
    
pathCell = regexp(path, pathsep, 'split');
if ispc  % paths are not case-sensitive
  onPath = any(strcmpi(folder, pathCell));
else
  onPath = any(strcmp(folder, pathCell));
end

end
