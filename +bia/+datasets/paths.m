function path = paths(dataset, type, version)
% Returns paths of all datasets
% 
% Inputs:
%     dataset: name of dataset
%     type: 'mat' (default), 'orig'
% 
% Datasets:
%     'Hist-BM'
%     'PhC-HeLa-Ox'
%     CTC-2D:
%     ''
%     CTC-3D:
%     ''
if nargin == 1
    type = 'mat';
end
if nargin < 3
    version = 0;% default
end

paths = get_paths();
root_default = paths.data_mat.root1;
root_bioviz_common  = paths.data.bioviz_common;
root_bioviz_mine    = paths.data.bioviz_mine;

if version == 0
    root        = paths.data_mat.root1;
else
    root        = fullfile(paths.data_mat.root1, sprintf('v%d', version));
end
ctc_names           = {'DIC-C2DH-HeLa', 'Fluo-C2DL-MSC', 'Fluo-C3DH-H157', 'Fluo-C3DL-MDA231', 'Fluo-N2DH-GOWT1', 'Fluo-N2DH-SIM', 'Fluo-N2DH-SIM+', ...
    'Fluo-N2DL-HeLa', 'Fluo-N3DH-CE', 'Fluo-N3DH-CHO', 'Fluo-N3DH-SIM', 'Fluo-N3DH-SIM+', 'Fluo-N3DL-DRO', 'PhC-C2DH-U373', 'PhC-C2DL-PSC'};
% remove seq number at the end
seq_num = str2double(dataset(end-1:end));
if ~isempty(seq_num) && ~isnan(seq_num) && seq_num ~= 73
    dataset = dataset(1:end-3);
end

if strcmp(type, 'mat')
    %% paths of mat files
    if ismember(dataset, {'Hist-BM', 'PhC-HeLa-Ox'})
        path = root;
    elseif ismember(dataset, ctc_names)
        path = root;
    elseif ismember(dataset, 'xyz')
    end
elseif strcmp(type, 'orig')
    %% paths of original files
    if ismember(dataset, 'Hist-BM')
        path = fullfile(root_bioviz_mine, '[Dataset-list]', 'MICCAI2015-Regression');
    elseif ismember(dataset, 'PhC-HeLa-Ox')
        path = fullfile(root_default, 'MATLAB', 'external', 'oxford_counting', 'CellDetect_v1.0', 'phasecontrast');
    elseif ismember(dataset, ctc_names)
        path = fullfile(root_bioviz_common, 'ISBI15-Cell Tracking Challenge', 'Train');
    end
end
end