function success = mkdir(path)
% creates the directory specified (only if it does not already exist)
% 
% Inputs:
%     path: directory path
% Outputs:
%     made: true(directory created)
% 

success = true;
if exist(path, 'dir') == 0
  success = mkdir(path);
end
if nargout == 0
    clear success
end
