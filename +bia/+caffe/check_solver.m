function check_solver(fname)
% checks that the network prototxt pointed in solver prototxt exists
% 
% Inputs:
%     fname : path of solver file
% 

fin = fopen(fname);
tline = fgets(fin);
if strcmp(tline(1:4), 'net:')
    idx = strfind(tline, '"');
    net_path = tline(idx(1)+1: idx(2)-1);
    if ~exist(net_path, 'file')
        error('Network : "%s"\npointed in solver: "%s" does not exist\n', net_path, fname)
    end
else
    error('solver: "%s" does not point to any network in first line\n', fname)
end
fclose(fin);
end