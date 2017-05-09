function save_solver(solver, file)
% saves the caffe solver settings to the solver prototxt file
%
% Inputs:
%     file : path of file where solver will be saved
%     solver : structure which contains the settings of solver
%
names = fieldnames(solver);
str = [];
for i=1:length(names)
    if isnumeric(solver.(names{i}))
        str = sprintf('%s%s: %s\n', str, names{i}, bia.utils.num2str(solver.(names{i})));
    else
        str = sprintf('%s%s: "%s"\n', str, names{i}, solver.(names{i}));
    end
end
fid = fopen(file, 'w+');
fprintf(fid, '%s%s: %d', str);
fclose(fid);
% fprintf('Solver saved: %s\n', file);

bia.caffe.check_solver(file);
end