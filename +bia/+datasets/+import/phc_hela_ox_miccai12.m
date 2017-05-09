function phc_hela_ox_miccai12()
% Dataset Info:
%     contains 22 grayscale images and centroid locations (x,y) of 2228 cells
%     4th image in test folder has 1 duplicate gt marker (exact same centroid location as another cell)
%     seq1 <- data in training folder
%     seq2 <- data in test folder
%
% Needs vlfeat for mser
%

paths = get_paths();
root = paths.data.phc_hela_ox;
root_export = paths.data_mat.root1;

dataset_name= 'PhC-HeLa-Ox';
N           = 22; % # of images
seq_ids     = {1:N/2; N/2+1:N};% image ids in a sequence
disp_seg    = 1;
opts_mser   = struct('delta', 1, 'area_range', [5, 1000], 'area_var', 0.25, 'nms_overlap', 0.2, 'ext_feat_set', 2, 'BrightOnDark', 0, 'DarkOnBright',1);

% read data from dataset folder
global im_all_cells_phc_ox gt_all_cells_phc_ox
im_all_cells_phc_ox = [];
if isempty(im_all_cells_phc_ox)
    im_all_cells_phc_ox = cell(N,1);
    gt = cell(N,1);
    for s = 1:2
        if s == 1%train dir
            offset      = 0;
            dir_name    = 'trainPhasecontrast';
        else% test dir
            offset      = 11;
            dir_name    = 'testPhasecontrast';
        end
        for i=1:11
            k = i+offset;
            im_all_cells_phc_ox{k} = imread(fullfile(root, dir_name, sprintf('im%02d.pgm', i)));
            tmp   = load(fullfile(root, dir_name, sprintf('im%02d.mat', i)));
            gt{k} = tmp.gt;
            % remove duplicate cell markers
            d       = pdist2(gt{k}, gt{k}) + 999*eye(size(gt{k},1));
            [r, ~]  = find(d==0);
            if ~isempty(r)
                fprintf('Duplicate cell markers found: %d cell has %d duplicates. %d\n', r(1), length(r)-1)
                gt{k}(r(1),:) = [];
            end
        end
    end
    gt_all_cells_phc_ox    = gt;
    num_cells       = sum(arrayfun(@(x) size(x{1},1), gt));
    fprintf('Oxford  - MICCAI 12 Phase Contrast dataset has %d cells in %d images\n', num_cells, N);
end

for s = 1:2
    % split data in 2 parts
    im_ids      = seq_ids{s};
    im_inter    = im_all_cells_phc_ox(im_ids);
    gt_inter    = gt_all_cells_phc_ox(im_ids);
    clear gt ims im_vid masks% clear variables from previous seq
    
    % create GT struct
    gt.T            = length(im_inter);
    gt.sz           = size(im_inter{1});
    gt.foi_border   = 0;
    gt.dim          = 2;
    seq_name = sprintf('%s-%02d', dataset_name, s);
    for t = 1:gt.T
        tic
        im          = im_inter{t};
        gt_cents    = gt_inter{t};
        sz          = [size(im,1), size(im,2)];
        gt_cents_idx= sub2ind(sz, gt_cents(:,2), gt_cents(:,1));
        
        stats       = bia.seg.mser(opts_mser, im);
        
        % fill holes in mser regions: sometimes a small (dark) region can be inside a brighter region and overlap does not detect it if hole filling is not used.
        for i=1:length(stats)
            mask = bia.convert.stat2im(stats(i), gt.sz);
            %            mask = imclose(mask, ones(2));
            mask = imfill(mask, 'holes');
            mask(mask>0) = 1;
            stmp = regionprops(mask, 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');
            stats(i) = stmp(1);
        end
        
        clear mser_info
        mser_info   = zeros(length(stats), 3);% [# of gt markers in the mser region, area of the mser region, id of 1st gt cell]
        gt_found    = cell(gt.T, 1);
        for i=1:length(stats)
            gt_idx_in_mser  = intersect(gt_cents_idx, stats(i).PixelIdxList);% get gt idx which are inside current mser region
            if ~isempty(gt_idx_in_mser)
                mser_info(i,:) = [1 stats(i).Area find(gt_cents_idx == gt_idx_in_mser(1))];
            end
            gt_found{i}     = gt_idx_in_mser;% idx of gt cells which are in the mser region
        end
        gt_found        = unique(cell2mat(gt_found));
        mser_errors     = find(mser_info(:,1)~=1);% idx of eroneous mser region containing 0 or 1+ gt markers
        stats(mser_errors)          = [];
        mser_info(mser_errors, :)   = [];
        mser_info(:, 4)             = 1:size(mser_info, 1);% add mser region ids
        
        mser_picked = pick_mser_regions(gt_cents, mser_info, stats);
        stats       = stats(mser_picked);
        
        % save image and GT data
        ims{t,1}          = im;
        
        l1 = length(stats);
        areas = [stats(:).Area];
        stats(areas == 0) = [];
        gt.seg.stats{t,1} = stats;
        gt.seg.info(t,:)  = [t, 0, 1];
        
        masks{t,1} = bia.convert.stat2im(stats, [size(im,1), size(im,2)]);
        
        if length(stats) ~= l1
            fprintf('0 sized region at: %d\n', t)
        end
        gt.detect{t,1} = gt_cents;
        %cell2mat(arrayfun(@(x) x.Centroid, stats, 'UniformOutput', false));
        
        %         assert(size(gt_cents, 1) == length(gt.detect{t}), '# Tracking markers saved not same as # GT markers')
        fprintf('t:%d (#GT:%d), #Found:%d -> took %1.2f sec:: GTs in any mser:%d, #MSER deleted(0 or 1+ marker):%d\n', t, size(gt_cents, 1), length(stats), toc, length(gt_found), length(mser_errors))
        
        if disp_seg
            im_seg  = bia.convert.l2rgb(bia.convert.stat2im(stats, gt.sz(1:2)));
            im_gt   = insertShape(im, 'FilledCircle', [gt_cents, 3*ones(size(gt_cents,1),1)]);
            im_gt   = insertShape(im_gt, 'Rectangle', bia.convert.bb(stats,'s2m'));
            figure(100)
            im_vid{t,1} = cat(2, im_gt, 255*ones(gt.sz(1), 20, 3), im_seg);
            imshow(im_vid{t})
            drawnow
        end
    end
    if disp_seg
        bia.save.video(im_vid, fullfile(root_export, sprintf('%s-seg.avi', seq_name, s)))
    end
    
    
    gt = bia.datasets.format(ims, '', '', '', gt_inter, struct('detect','tra','foi_border',0,'name',seq_name,'split',s));
    save(fullfile(root_export, sprintf('%s-GT.mat', seq_name)), 'gt')
    gt = bia.datasets.format(ims, masks, '', gt_inter, [], struct('detect','tra','foi_border',0,'name',seq_name,'split',s,'fully_seg_ratio',0.9));
    save(fullfile(root_export, sprintf('%s-norm.mat', seq_name)), 'ims')
    save(fullfile(root_export, sprintf('%s-orig.mat', seq_name)), 'ims')% orig and norm image are same
    save(fullfile(root_export, 'v1', sprintf('%s-GT.mat', seq_name, s)), 'gt')
end
end
function mser_picked = pick_mser_regions(gt_cents, mser_info, stats)
% Selects mser regions to be used as GT

% finds the mser's containing each gt and sort them by their areas
M = size(gt_cents,1);
gt_mser_map    = 999999*ones(M,2);% row(gt num) -> [max_area, mser_id]
msers_matched  = cell(M,2);% row(gt num) -> [areas in descend, mser_id for areas]
for k = 1:M
    idx         = find(mser_info(:,3)==k);
    if ~isempty(idx)
        idx_mser    = mser_info(idx,4);
        areas       = mser_info(idx,2);
        [areas_s, aidx] = sort(areas, 'descend');
        assert(isequal(areas_s, areas(aidx)), 'Areas Fixed')
        idx_mser    = idx_mser(aidx);
        
        gt_mser_map(k, 1) = idx_mser(1);
        gt_mser_map(k, 2) = areas_s(1);
        msers_matched{k, 1} = idx_mser;
        msers_matched{k, 2} = areas_s;
    end
end

% start from smallest mser (among the largest mser for each gt)
% If it contains another already found mser region then pick a smaller mser until it contains no already found mser region
mser_picked = [];
for k = 1:M
    [~, gt_id] = min(gt_mser_map(:,2));
    mser_id = gt_mser_map(gt_id, 1);
    if mser_id == 999999% skip cells which are outside all msers
        continue
    end
    if isempty(mser_picked)% pick the first mser region directly
        mser_picked = [mser_picked; mser_id];
    else% check overlap with existing mser regions to ensure that it is not a bad region
        o = op_int(stats(mser_id), stats(mser_picked));
        if max(o) > 0.5
            found = 0;% indicates that a non-overlapping mser is found
            overlaps  = ones(length(msers_matched{gt_id,1}), 1);
            for i = 1:length(msers_matched{gt_id,1})
                mser_id = msers_matched{gt_id,1}(i);
                o = op_int(stats(mser_id), stats(mser_picked));
                overlaps(i) = max(o);
                if max(o) < 0.5
                    mser_picked = [mser_picked; mser_id];
                    found = 1;
                    break;
                end
            end
            if found == 0% if non-overlapping not found, pick the smallest one
                mser_picked = [mser_picked; msers_matched{gt_id,1}(end)];
            end
        else
            mser_picked = [mser_picked; mser_id];
        end
    end
    gt_mser_map(gt_id,:) = [];
    msers_matched(gt_id,:) = [];
end
% find the overlap of picked mser with previously selected msers
end
function o = op_int(s1, s2)
% compute the overlap (intersect(A,B)/length(B)) of current mser with previously/already found msers
bbox_overlap_threshold  = 0.8;
se_close                = ones(8);
sz                      = [400, 400];
px1 = s1.PixelIdxList;
% pixel overlap
for i=1:length(s2)
    o(i) = sum(ismember(px1, s2(i).PixelIdxList))/length(s2(i).PixelIdxList);% 3-5x faster than using intersect % slowest part in this func
end
% close and hole fill to compute 2nd pixel overlap
mask = bia.convert.stat2im(s1, sz);
mask = imclose(mask, se_close);
mask = imfill(mask, 'holes');
mask(mask>0) = 1;
s3 = regionprops(mask, 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');
for i=1:length(s2)
    o(i) = max(o(i), sum(ismember(s3(1).PixelIdxList, s2(i).PixelIdxList))/length(s2(i).PixelIdxList));% 3-5x faster than using intersect % slowest part in this func
end
% use bbox to compute the 3rd overlap: used to ignore mser regions (thresholded at high values and contain bright boundaries around other cells) which surround other cells
bb      = s1.BoundingBox;
bb(3:4) = [bb(1)+bb(3), bb(2)+bb(4)];
for i=1:length(s2)
    bb2     = s2(i).BoundingBox;
    area2   = bb2(3)*bb2(4);
    bb2(3:4)= [bb2(1)+bb2(3), bb2(2)+bb2(4)];
    area_common = max(0, min(bb(3), bb2(3))-max(bb(1), bb2(1))+1) * max(0, min(bb(4), bb2(4))-max(bb(2), bb2(2))+1);
    if area_common/area2 > bbox_overlap_threshold
        o(i) = max(o(i), area_common/area2);
    end
end
end