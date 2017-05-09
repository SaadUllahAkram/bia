function path = add_code(packages)
% code paths
packages_list = {'gco', 'gridcut', 'bia', 'frcnn', 'cpn', 'vlfeat', 'cellsegm', 'celldetect', 'bernsen', 'blob', 'simple_tracker', 'gurobi'};
if nargin == 0% print all packages that can be imported
    fprintf('List of codes that can be imported:\n')
    for i=1:length(packages_list)
        fprintf('%s\n', packages_list{i})
    end
    return
end

paths_all   = get_paths();
root   = paths_all.code.matlab;

path        = [];
if ischar(packages)
    tmp{1}  = packages;
    packages = tmp;
end


N = length(packages);
paths = cell(N,1);
for i=1:N
    package = packages{i};

    if strcmp(package, 'gco')
        path = fullfile(root, 'external', 'GraphCuts', 'gco-v3.0');
    elseif strcmp(package, 'gridcut')
        path = fullfile(root, 'external', 'GraphCuts', 'GridCut-1.3', 'matlab');
    elseif strcmp(package, 'bia')
        path = fullfile(root, 'packages');
    elseif strcmp(package, 'frcnn')
        path = fullfile(root, 'packages', 'faster_rcnn');
    elseif strcmp(package, 'cpn')
        path = fullfile(root, 'CPN');
    elseif strcmp(package, 'vlfeat')
        if exist('vl_setup','file') == 0
            path = fullfile(root, 'external', 'vlfeat-0.9.20-bin', 'toolbox', 'vl_setup.m');
        end
    elseif strcmp(package, 'cellsegm')
        path = fullfile(root, 'external', 'cellsegm', 'startupcellsegm.m');
    elseif strcmp(package, 'celldetect')
        path = fullfile(root, 'external', 'oxford_counting', 'CellDetect_v1.0');
    elseif strcmp(package, 'bernsen')
        path = fullfile(root, 'external', 'bernsen');
    elseif strcmp(package, 'blob')
        path = fullfile(root, 'external', 'code_blobDetector2013');
    elseif strcmp(package, 'simple_tracker')
        path = fullfile(root, 'external', 'SimpleTracker');
    elseif strcmp(package, 'gurobi')
        if exist('gurobi_setup', 'file') ~= 2
            path = fullfile(paths_all.softwares.gurobi, 'gurobi_setup.m');
        else
            path = paths_all.softwares.gurobi;
        end
    elseif strcmp(package, 'xyz')
    end

    if exist(path, 'file') == 2
        run(path)
    elseif exist(path, 'dir')
        addpath(genpath(path))
    elseif ~isempty(path)
        error('Path: "%s" isneither dir nor file', path)
    end
    paths{i} = path;
end

if length(paths) == 1
    path = paths{1};
else
    path = paths;
end

if nargout == 0
    clear path
end

end