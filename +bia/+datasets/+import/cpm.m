function cpm()
% imports histological cell segmentation data from cpm challenge (miccai 2016)
% 

paths = get_paths();
path_cache = paths.temp;
zip_file = fullfile(paths.data.cpm16, 'segmentation_training.zip');
if ~exist(zip_file, 'file')
    warning('CPM data not found at: %s', zip_file)
    return
end
unzip(zip_file, path_cache)
root = fullfile(path_cache, 'segmentation_training');
root_mat = paths.data_mat.root1;% where data will be saved

bia.save.mkdir(root_mat)

cancers = {'gbm', 'hnsc', 'lgg', 'lung'};
fun_mat = @(d, s, type) fullfile(root_mat, sprintf('%s-%02d-%s.mat', d, s, type));
D = length(cancers);
ims_comb = cell(D,2);
masks_comb = cell(D,2);
for d=1:D% save data for indibidual cancers
    dataset_name = sprintf('%s-%s','cpm',cancers{d});
    
    root_data = fullfile(root, cancers{d}, 'training-set');
    list = dir([root_data, filesep, 'image*.txt']);

    mid = round(length(list)/2);
    splits{1} = 1:mid;
    splits{2} = mid+1:length(list);
    for s=1:2
        idx = splits{s};
        T = length(idx);
        ims = cell(T,1);
        masks = cell(T,1);
        ims_comb{d,s} = cell(T,1);
        masks_comb{d,s} = cell(T,1);
        for i=1:T
            ims{i} = imread(fullfile(root_data, sprintf('image%02d.png', idx(i))));
            masks{i} = mask_read(fullfile(root_data, sprintf('image%02d_mask.txt', idx(i))));
            
            ims_comb{d,s}{i} = ims{i};
            masks_comb{d,s}{i} = masks{i};
        end
        gt = bia.datasets.format(ims, masks, [], [], [], struct('detect','seg','foi_border',-1,'name',dataset_name,'split',s));
        save(fun_mat(dataset_name, s, 'norm'), 'ims')
        ims_orig = ims;
        save(fun_mat(dataset_name, s, 'orig'), 'ims_orig')
        save(fun_mat(dataset_name, s, 'GT'), 'gt')
    end
end

% save combined data
dataset_name = 'cpm';
for s=1:2
    T = sum(arrayfun(@(x) length(x{1}), ims_comb(1:D,s)));
    ims = cell(T,1);
    masks = cell(T,1);
    idx = 0;
    for d=1:D
        for i=1:length(ims_comb{d,s})
            idx = idx+1;
            ims{idx} = ims_comb{d,s}{i};
            masks{idx} = masks_comb{d,s}{i};
        end
    end
    gt = bia.datasets.format(ims, masks, [], [], [], struct('detect','seg','foi_border',-1,'name',dataset_name,'split',s));
    save(fun_mat(dataset_name, s, 'norm'), 'ims')
    ims_orig = ims;
    save(fun_mat(dataset_name, s, 'orig'), 'ims_orig')
    save(fun_mat(dataset_name, s, 'GT'), 'gt')
end

end

function mask = mask_read(file)
M = dlmread(file);
szx = M(1,:);
mask = M(2:end,1);
mask = reshape(mask, szx)';
end