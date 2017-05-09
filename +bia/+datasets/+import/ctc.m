function gt = ctc(dataset, version, set)
% only imports 2D datasets
if nargin < 2
    version = [0 0];% [gt_version, ims_version]
end
if nargin < 3
    set = [1 0];
end
paths = get_paths();

opts.import_ims = 1;
opts.dataset = dataset;
opts.version = version;
opts.set = set;
opts.path_ctc = paths.data.ctc;
opts.path_cache = paths.temp;
opts.path_mat = paths.data_mat.root1;% where data will be saved
bia.save.mkdir(opts.path_mat)

for train = opts.set% which set to import
    clearvars -except train opts
    % get paths and extract zip
    if train == 0
        root = fullfile(opts.path_ctc,'Test');
        cache = fullfile(opts.path_cache, 'Test');
        test_str = 'test-';
    else
        root = fullfile(opts.path_ctc,'Train');
        cache = fullfile(opts.path_cache, 'Train');
        test_str = '';
    end
    %     if exist(fullfile(cache, opts.dataset), 'dir')
    %         % delete(fullfile(cache, opts.dataset))
    %     end
    bia.save.mkdir(cache)
    zip_file = fullfile(root, [opts.dataset, '.zip']);
    if ~exist(zip_file, 'file')
        warning('CTC data not found at: %s\n', zip_file)
        continue
    end
    unzip(zip_file, cache);
    
    % version specific changes:
    for s = 1:get_num_sequences(opts.dataset)
        clearvars -except s root test_str train opts cache
        t_start = tic;
        opts_norm = get_prep_opts(opts.dataset, opts.version(2));
        seq_name = sprintf('%s-%02d', opts.dataset, s);
        seq_str  = num2str(s, '%02d');
        paths.mat_gt= fullfile(opts.path_mat, sprintf('%s%s-GT.mat', test_str, seq_name));
        if opts.version(2) == 0
            paths.mat_norm = fullfile(opts.path_mat, sprintf('%s%s-norm.mat', test_str, seq_name));
        else
            paths.mat_norm = fullfile(opts.path_mat, sprintf('v%d',opts.version(2)), sprintf('%s%s-norm.mat', test_str, seq_name));
        end
        paths.mat_orig = fullfile(opts.path_mat, sprintf('%s%s-orig.mat', test_str, seq_name));
        
        paths.tif   = fullfile(cache, opts.dataset, seq_str);
        paths.gt    = fullfile(cache, opts.dataset, [seq_str, '_GT']);
        paths.gt_seg= fullfile(paths.gt, 'SEG');
        paths.gt_tra= fullfile(paths.gt, 'TRA');
        %% Import Images
        fprintf('Normalizing: %s%s', test_str, seq_name)
        list_seq_tif = dir([paths.tif, filesep, '*.tif']);
        T = length(list_seq_tif);
        ims_pass1 = cell(T,1);
        ims_orig = cell(T,1);
        ims = cell(T,1);
        if opts.import_ims || ~exist(paths.mat_norm, 'file')
            norm_mat = zeros(T,2);
            clear norm_mat norm_values im
            [~,ax] = bia.plot.fig('ims');
            for pass = 1:2% scan (pass 1) & normalize (pass 2)
                fprintf('\nStarting pass %d::', pass)
                if pass == 2
                    if strcmp(opts_norm.bg_removal, '2')% 2: disk filter
                        bg = bg_model(ims_pass1, 'disk');
                        for t=1:T% get norm values after bg removal
                            ims_pass1{t} = ims_pass1{t}-bg;
                            norm_mat(t, :) = get_norm_values(opts_norm, ims_pass1{t});
                        end
                    end
                    norm_values = median(norm_mat, 1);
                end
                for t=1:T
                    fprintf('%d ', t)
                    if pass == 1
                        im = single(bia.read.tif(fullfile(paths.tif, sprintf('t%03d.tif', t-1))));
                        ims_orig{t} = im;
                        % median filtering
                        if opts_norm.median_kernel > 0
                            im = medfilt2(im, [opts_norm.median_kernel opts_norm.median_kernel]);
                        end
                        % hole filling
                        if opts_norm.fill_holes
                            im = imfill(im, 'holes');
                        end
                        % normalization
                        norm_mat(t, :) = get_norm_values(opts_norm, im);
                        ims_pass1{t} = im;
                    end
                    if pass == 2
                        im = ims_pass1{t};
                        im = uint8(255*(im - norm_values(1))/ (norm_values(2) - norm_values(1)));
                        ims{t} = im;
                        cla(ax)
                        imshow(ims{t},[0 255], 'parent', ax);
                        drawnow
                    end
                end
            end
            save(paths.mat_norm, 'ims')
            save(paths.mat_orig, 'ims_orig')
            fprintf('\nims saved in: %s\n', paths.mat_norm)
        else
            load(paths.mat_norm, 'ims')
        end
        
        %% Import GT
        list_seg = dir([paths.gt_seg, filesep, '*.tif']); % names of GTseg files
        list_tra = dir([paths.gt_tra, filesep, '*.tif']);
        N = length(list_seg); % num of slices/frames with GT seg
        masks = cell(T,1);
        markers = cell(T,1);
        gt_tra_info_file = fullfile(paths.gt_tra, 'man_track.txt');
        if exist(gt_tra_info_file, 'file')
            tra_info = ctc_read_track_txt(gt_tra_info_file);
        else
            tra_info = [];
        end
        for i = 1:N% get seg masks
            fname = list_seg(i).name; % name of gt .tif file
            [t, z] = get_t_z(fname);
            masks{t} = bia.read.tif(fullfile(paths.gt_seg, fname));
            %figure(1);  imshow(bia.draw.boundary([], ims{t}, masks{t}))
        end
        for i=1:length(list_tra)% get tra markers
            t = sscanf(list_tra(i).name, 'man_track%d.tif')+1;
            markers{t} = bia.read.tif(fullfile(paths.gt_tra, list_tra(i).name));
        end
        if train == 1
            [masks, markers, tra_info] = fix_errors(opts.dataset, s, masks, markers, tra_info);
        end
        if strcmp(opts.dataset, 'PhC-C2DH-U373')
            fully_seg_ratio = 0.6;
        else
            fully_seg_ratio = 0.8;
        end
        gt = bia.datasets.format(ims, masks, markers, tra_info, [], struct('detect','tra','foi_border',get_foi(opts.dataset),'name',opts.dataset,'split',s,'fully_seg_ratio',fully_seg_ratio));
        % mark borders in touch with an object
        % gt.seg.stats = mark_border_samples(gt.seg.stats, gt.sz);
        save(paths.mat_gt, 'gt');
        fprintf('gt saved in: %s\n', paths.mat_gt)
        fprintf('Track processing finshed at: %1.2f sec\n', toc(t_start))
    end
    % rmdir(cache)
end
end


function [bg, bg_min, bg_max] = bg_model(im, method)
T = length(im);
ims = zeros([size(im{1},1) size(im{1},2) T]);
for t=1:T
    ims(:,:,t) = single(im{t});
end
if strcmpi(method, 'disk') % remove disk
    fs = fspecial('gaussian', 100, 30);
    im_min = min(ims,[],3);
    im_min = medfilt2(im_min,[7 7]);
    bg = imfilter(im_min,fs,'symmetric','same');
end
bg_min = min(bg(:));
bg_max = max(bg(:));
end


function num_seq = get_num_sequences(dataset)% returns # of sequenes in the given dataset
if strcmp(dataset, 'Fluo-N2DH-SIM')
    num_seq = 6;
else
    num_seq = 2;
end
end


function foi = get_foi(dataset)% returns border width outside foi in the given dataset
if ismember(dataset, {'DIC-C2DH-HeLa', 'Fluo-C2DL-MSC', 'Fluo-C3DH-H157', 'Fluo-N2DH-GOWT1', 'Fluo-N3DH-CE', 'Fluo-N3DH-CHO', 'PhC-C2DH-U373'})
    foi = 50;
elseif ismember(dataset, {'Fluo-C3DL-MDA231', 'Fluo-N2DL-HeLa', 'PhC-C2DL-PSC'})
    foi = 25;
elseif ismember(dataset, {'Fluo-N2DH-SIM', 'Fluo-N2DH-SIM+','Fluo-N3DH-SIM', 'Fluo-N3DH-SIM+', 'Fluo-N3DL-DRO'})
    foi = 0;
end

end


function prep = get_prep_opts(dataset, version)
prep = struct('median_kernel', 0, 'norm_type', 'percentile', 'lower', 0.01,  'upper', 99.9, 'bg_removal', '0', 'fill_holes', 0);
if strcmp(dataset, 'Fluo-N2DL-HeLa')
    prep = bia.utils.setfields(prep, 'median_kernel', 3, 'norm_type', 'percentile', 'lower', 0.01,  'upper', 99.9);
elseif strcmp(dataset, 'Fluo-N2DH-GOWT1')
    prep = bia.utils.setfields(prep, 'median_kernel', 5, 'norm_type', 'minmax', 'fill_holes', 1);
elseif strcmp(dataset, 'PhC-C2DL-PSC')
    if version == 1
        prep = bia.utils.setfields(prep, 'norm_type', 'minmax', 'bg_removal', '2');
    else
        prep = bia.utils.setfields(prep, 'norm_type', 'minmax');
    end
    %prep = bia.utils.setfields(prep, 'norm_type', 'percentile', 'lower', 0,    'upper', 100);
elseif strcmp(dataset, 'PhC-C2DH-U373')
    prep = bia.utils.setfields(prep, 'norm_type', 'minmax');
elseif strcmp(dataset, 'DIC-C2DH-HeLa')
    prep = bia.utils.setfields(prep, 'norm_type', 'percentile');
elseif strcmp(dataset, 'Fluo-C2DL-MSC')
    prep = bia.utils.setfields(prep, 'median_kernel', 5, 'norm_type', 'percentile', 'lower', 0.01,  'upper', 99.99, 'bg_removal', '1');
elseif strcmp(dataset, 'Fluo-N2DH-SIM')
    prep = bia.utils.setfields(prep, 'median_kernel', 5, 'norm_type', 'percentile', 'lower', 0.01,  'upper', 99.99);
elseif strcmp(dataset, 'Fluo-N2DH-SIM+')
    prep = bia.utils.setfields(prep, 'median_kernel', 5, 'norm_type', 'percentile', 'lower', 0.01,  'upper', 99.99);
end
end


function n = get_norm_values(opts_norm, im)
if strcmp(opts_norm.norm_type, 'minmax')%isa(class(im), 'uint8')
    n = [min(im(:)), max(im(:))];
elseif strcmp(opts_norm.norm_type, 'percentile')
    n = double(prctile(single(im(:)), [opts_norm.lower, opts_norm.upper]));
end
end


function [t, z] = get_t_z(fname)% get t and slice number given the GT seg mask file name
if length(fname) > 14
    [tmp] = sscanf(fname, 'man_seg_%d_%d.tif')+1;
    t = tmp(1);
    z = tmp(2);
    if length(tmp) == 1
        z = 0;
    end
else
    t = sscanf(fname, 'man_seg%d.tif')+1;
    z = 0;
end
end


function tracks = ctc_read_track_txt(filePath)
% Reads data (cell event) from track man text file returns tracks = 4xInf
% time in output starts from '1' instead of '0'
%
% Inputs:
% 	filePath : complete path of cell tracking challenge's tracks file.
% Outputs:
% 	tracks : Size=[4 x num of Tracks], Each Row[Track ID, TrackStart, TrackEnd, TrackParent], TrackParent==0, if no parent
%

fileID = fopen(filePath, 'r');
sizeMat = [4 Inf];
tracks = fscanf(fileID,'%d %d %d %d\n', sizeMat)';
tracks(:,2:3) = tracks(:,2:3) + 1; % convert 0-based indexing to 1-based
fclose(fileID);
end


function [masks, markers, tra_info] = fix_errors(dataset, s, masks, markers, tra_info)
% tra errors
if strcmp(dataset, 'Fluo-N2DL-HeLa')
    if s == 2% delete 839 at t 37
        assert(sum(sum(markers{37} == 839))>0)
        markers{37}(markers{37} == 839) = 0;
        assert(unique(tra_info(tra_info(:, 1) == 839, [2 3])) == 37)
        tra_info(tra_info(:,1) == 839, :) = [];
    end
end

% seg errors
if strcmp(dataset, 'PhC-C2DL-PSC') && s == 2
    % delete and remove the gap: psc-02-t26-id30: too small and same as bg so cant be a cells
    masks{26}(masks{26} == 30) = 0;
    masks{26}(masks{26} > 30) = masks{26}(masks{26} > 30)-1;
end

if strcmp(dataset, 'PhC-C2DL-PSC') && s == 1% fix errors in some very big bboxes
    for t=123
        stats = regionprops(masks{t},'Area','BoundingBox','Centroid','PixelIdxList');
        sz = size(masks{t});
        clear stats_fixed
        for u=1:length(stats)
            im = bia.convert.stat2im(stats(u), sz) > 0;
            stats2 = regionprops(im,'Area','BoundingBox','Centroid','PixelIdxList');
            for j=1:length(stats2)
                if ~exist('stats_fixed','var')
                    stats_fixed = stats2(j);
                else
                    stats_fixed(end+1,1) = stats2(j);
                end
            end
        end
        assert(length(stats_fixed)+1 ~= length(unique(masks{t})))
        masks{t} = bia.convert.stat2im(stats_fixed, sz);
    end
end

if strcmp(dataset, 'Fluo-N2DL-HeLa')
    if s == 1
        assert(masks{40}(1, 314) == 12)
        masks{40}(1, 314) = 0;%'man_seg039.tif'
    elseif s == 2
        assert(masks{36}(693, 702) == 6);%'man_seg035.tif'
        masks{36}(693, 702) = 0;
        masks{36}(692, 703) = 0;
        %'man_seg079.tif'
        % fix 1st error
        im2 = masks{80} == 6;% only retain mistaken region
        im3 = bwlabeln(im2);
        % merge this part with the nearby cell
        id = im3(633, 1032);
        masks{80}(im3 == id) = 272;
        % fix 2nd error
        im2 = masks{80}==111;% only retain mistaken region
        im3 = bwlabeln(im2);
        id  = im3(35, 450);
        masks{80}(im3 == id) = 0;
    end
end

end