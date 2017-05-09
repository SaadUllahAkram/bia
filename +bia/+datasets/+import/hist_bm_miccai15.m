function hist_bm_miccai15()
% Dataset Info:
%     contains 11 RGB images and centroid locations (x,y) of 4202 cells.
%     All cell markers use only 1 pixel each.
%     There are 3 cell markers touching another cell marker (these are deleted)
%     seq1 <- first 5 images
%     seq2 <- images 6-11
%
% Needs gco-v3 for multi-label Graph Cuts and pcsel for assigning different labels to nearby cells
%
% P. Kainz, M. Urschler, S. Schulter, P. Wohlhart, and V. Lepetit, ?You Should Use Regression to Detect Cells,? in Proceedings of the International Conference on Medical Image Computing and Computer Assisted Intervention (MICCAI), 2015, pp. 1?8.
%
% Paper mentions 4205 cells in 11 images, however the datset has 3 errors (3 markers (single pixels) are right next to another cell marker (single pixels)), these are ignored, so it contain 4202 cells
%


% error('use old segmentation, new code has worse performance')
bia.add_code('gco')
paths = get_paths();
dataset_name= 'Hist-BM';
seq_ids     = {1:5; 6:11};% image ids in a sequence
disp_seg    = 1;
root = paths.data.hist_bm;
root_export = paths.data_mat.root1;

bg_dist     = 20;% 20 is a bit tight, 30 is too much
fg_dist     = 6;% 16 is too much, upto 8 or 10 may work
w           = 10;% relative weight of n-links/t-links
top_cost    = 2^16;% cost for fixing topological links
% set n-link costs to very high for pixels attached/fixed to t-nodes
max_cost    = 2^8;
small_marker= 0;

num_cols    = 7;
T_NODES     = num_cols+1;

global im_all_cells_reg gt_all_cells_reg
if isempty(im_all_cells_reg)
    dir_im  = fullfile(root, 'source');
    dir_gt  = fullfile(root, 'annotations');
    list_im = dir([dir_im, filesep, '*.png']);
    N       = length(list_im);
    
    im      = cell(N, 1);
    gt      = cell(N, 1);
    for i =1:N
        im{i}   = imread(fullfile(dir_im, list_im(i).name));
        im_gt   = imread(fullfile(dir_gt, strrep(list_im(i).name, '.png', '_dots.png')));
        num_gt  = sum(im_gt(:)>0);
        s       = regionprops(logical(im_gt), 'Area', 'Centroid');
        gt{i}   = bia.convert.centroids(s);
        if num_gt ~= size(gt{i}, 1)
            warning(sprintf('Image: %s has %d connected components (%d cell markers are connected with another cell marker)', strrep(list_im(i).name, '.png', '_dots.png'), size(gt{i}, 1), num_gt-size(gt{i}, 1)))
        end
        imshow(im{i})
        bia.plot.centroids([],s)
    end
    
    im_all_cells_reg = im;
    gt_all_cells_reg = gt;
    num_cells    = sum(arrayfun(@(x) size(x{1},1), gt_all_cells_reg));
    fprintf('Graz  - MICCAI 15 has %d cells in %d images\n', num_cells, length(im_all_cells_reg));
end

for s = 1:2
    seq_name = sprintf('%s-%02d', dataset_name, s);
    % split data in 2 parts
    im_ids      = seq_ids{s};
    
    im_inter    = im_all_cells_reg(im_ids);
    gt_inter    = gt_all_cells_reg(im_ids);
    clear gt ims im_vid masks% clear variables for previous seq
    
    gt.T            = length(im_inter);
    gt.sz           = size(im_inter{1});
    gt.dim          = 2;
    gt.foi_border   = 0;
    for t = 1:gt.T
        tic
        imo     = im_inter{t};
        im      = im2double(im_inter{t});
        gt_cents= gt_inter{t};
        sz      = [size(im,1), size(im,2)];
        colors  = bia.utils.pcsel(gt_cents, num_cols);
        N       = prod(sz);

        mask_gt    = zeros(sz);
        mask_gt(sub2ind(sz, gt_cents(:,2), gt_cents(:,1))) = 1;
        bg      = double(bwdist(mask_gt) > bg_dist);
        
        % create fg mask
        fg      = zeros(sz(1), sz(2));
        for u=1:num_cols
            mask    = zeros(sz);
            cents   = gt_cents(colors==u, :);
            mask(sub2ind(sz, cents(:,2), cents(:,1))) = 1;
            fg(bwdist(mask) < fg_dist) = u;
        end
        if 0
            figure(1)
            r=1;c=3;
            bia.plot.subplot(r,c,1);is(im)
            bia.plot.subplot(r,c,2);is(apply_mask([], im, bg))
            for u=1:num_cols
                bia.plot.centroids([],gt_cents(colors==u,:), col{u});
            end
            bia.plot.subplot(r,c,3);is(apply_mask([], im, fg))
            bia.plot.centroids([],gt_cents)
        end
        
        fprintf('Learning FG models->')
        fgc_all                     = fg_model(im, fg);
        fprintf('Learning BG models->')
        bgc                         = bg_model(im, bg);
        
        % normalize
        fgc     = max(fgc_all, [], 3);
        p       = cat(3, bgc, fgc);
        psum    =  sum(p, 3);
        psum(psum == 0) = 1;
        bgc     = max_cost*exp(-(p(:,:, 1)./psum)/0.25);
        % bgc     = top_cost*(1-(p(:,:, 1)./psum));
        % use topological info
        bg                  = logical(bg);
        bgc(bg(:))          = 0;
        bgc(fg(:)>0)        = top_cost;
        for u=1:num_cols
            mask    = zeros(sz);
            cents   = gt_cents(colors==u, :);
            idx00   = sub2ind(sz, cents(:,2), cents(:,1));
            mask(idx00) = 1;
            dist_map = bwdist(mask);
            dist_map(dist_map>30) = 0;
            
            fgcell{u}                   = max_cost*exp(-(fgc_all(:,:,u)./psum)/0.25) + 1*exp(dist_map./10);
            if small_marker
                fgcell{u}(idx00)         = 0;
            else
                fgcell{u}(fg(:)==u)      = 0;
            end
            
            if small_marker
                cents_oth   = gt_cents(colors~=u, :);
                idx00_oth   = sub2ind(sz, cents_oth(:,2), cents_oth(:,1));
                fgcell{u}(idx00_oth)         = top_cost;
            else
                for k=setdiff(1:num_cols, u)
                    fgcell{u}(fg(:)==k)         = top_cost;
                end
            end
            fgcell{u}(bg(:))   = top_cost;
        end
        % GCO_SetLabeling(Handle,Labeling)
        h = GCO_Create(N, T_NODES);% Create new object with NumSites=4, NumLabels=3
        t_costs = int32(bgc(:)');
        for tni = 1:T_NODES-1
            t_costs = [t_costs; fgcell{tni}(:)'];
        end
        fprintf('\nFinding Solution')
        GCO_SetDataCost(h,t_costs);
        penalty = w-diag(w*ones(1, T_NODES));
        % penalty(1, 2:end) = 10*penalty(1, 2:end);
        % penalty(2:end, 1) = 10*penalty(2:end, 1);
        GCO_SetSmoothCost(h, penalty);
        % http://stackoverflow.com/questions/3277541/construct-adjacency-matrix-in-matlab
        
        [dr, db] = imgradientxy(rgb2gray(im), 'IntermediateDifference');
        max_v = max(max(abs(dr(:))), max(abs(db(:))));
        dr = abs(dr)/max_v;
        db = abs(db)/max_v;
        % dl = circshift(dr, 1, 2);
        % du = circshift(db, 1, 1);
        % dr = dr(:,1:end-1);% last row of zeros removed as it causes diag to have larger size than NxN
        horiz   = 255*exp(-dr(:)/.1);
        vert    = 255*exp(-db(:)/.1);
        adj = spdiags(horiz,sz(1), N, N) + spdiags(vert, 1, N, N);
        
        GCO_SetNeighbors(h, adj);
        GCO_Expansion(h);% Compute optimal labeling via alpha-expansion
        lab = GCO_GetLabeling(h);
        
        [E, D, S] = GCO_ComputeEnergy(h);% Energy = Data Energy + Smooth Energy
        GCO_Delete(h);% Delete the GCoptimization object when finished
        lab = double(reshape(lab, sz))-1;
        lab1 = lab;
        fprintf('\nPost-Processing\n')
        % lab = bwareaopen(lab, 20);
        % lab = imerode(lab, ones(3));
        lab = imfill(lab, 'holes');
        
        % lab = bwareaopen(lab, 20);
        % lab = imclose(lab, ones(5));
        
        %         figure(2)
        %         r=1;c=5;
        %         bia.plot.subplot(r,c,1);is(im);
        %         bia.plot.subplot(r,c,2);is(reshape(fgc, sz));
        %         bia.plot.subplot(r,c,3);is(reshape(bgc, sz));
        %         bia.plot.subplot(r,c,4);is(bia.convert.l2rgb(lab1))
        %         bia.plot.subplot(r,c,5);is(lab);
        %         bia.plot.centroids([],gt_cents)
        %
        %         figure(3)
        %         r=1;c=2;
        %         bia.plot.subplot(r,c,1);is(im);
        %         bia.plot.subplot(r,c,2);is(apply_mask([], im, lab));
        %
        %         figure(4)
        %         is(lab);
        %         bia.plot.centroids([],gt_cents)
        %         drawnow
        % assign unique labels
        lab_new = 0*lab;
        for i=1:max(lab(:))
            clear tmp;
            tmp         = bwlabel(lab == i);
            tmp(tmp>0)  = tmp(tmp>0)+max(lab_new(:));
            lab_new     = tmp+lab_new;
        end
        stats = regionprops(lab_new, 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');
        % check that there is only 1 marker inside each region.
        cents = sub2ind([sz(1) sz(2)], gt_cents(:,2), gt_cents(:,1));
        idx_del = [];
        for i=1:length(stats)
            inter = intersect(stats(i).PixelIdxList, cents);
            if length(inter) ~= 1
                if length(inter) == 0
                    idx_del = [idx_del, i];
                else
                    fprintf('%d has %d cells\n', i, length(inter))
                end
            end
        end
        stats(idx_del) = [];
        
        ims{t,1}              = imo;
        gt.detect{t,1}      = gt_cents;
        gt.seg.stats{t,1}   = stats;
        
        masks{t,1} = bia.convert.stat2im(stats, [size(imo,1), size(imo,2)]);
        gt.seg.info(t,:)    = [t, 0, 1];
        if size(gt_cents, 1) ~= length(gt.seg.stats{t})
            fprintf('##############\nt:%d -> %d of %d GT cell marker (TRA stats) missing\n##############\n', t, length(gt.seg.stats{t}), size(gt_cents, 1))
        end
        fprintf('t:%d -> # GT: %d (%d), #Found: %d -> took %1.2f sec\n', t, size(gt_cents, 1), length(gt.seg.stats{t}), length(stats), toc)
        if disp_seg
            im_seg = bia.convert.l2rgb(bia.convert.stat2im(stats, gt.sz(1:2)));
            im_gt = insertShape(imo, 'FilledCircle', [gt_cents, 3*ones(size(gt_cents,1),1)]);
            im_vid{t,1} = cat(2, im_gt, im_seg);
            imshow(im_vid{t})
            drawnow
        end
    end
    
    gt = bia.datasets.format(ims, '', '', '', gt_inter, struct('detect','tra','foi_border',0,'name',seq_name,'split',s));
    save(fullfile(root_export, sprintf('%s-GT.mat', seq_name)), 'gt')
    gt = bia.datasets.format(ims, masks, '', gt_inter, [], struct('detect','tra','foi_border',0,'name',seq_name,'split',s,'fully_seg_ratio',0.9));
    
    bia.save.video(im_vid, fullfile(root_export, sprintf('%s-seg.avi', seq_name)))
    save(fullfile(root_export, sprintf('%s-norm.mat', seq_name)), 'ims')
    save(fullfile(root_export, sprintf('%s-orig.mat', seq_name)), 'ims')
    save(fullfile(root_export, 'v1', sprintf('%s-GT.mat', seq_name)), 'gt')
end
end
% Do for all classes/labels
%     % Do for all cells
%         % 1. Extract XxX patch -> X~=6
%         % 2. Fit a color model.
%         % 3. Apply color model to YxY -> Y~=30
%     combine (max) responses of all cells having same label
%     Set All Pixels outside Y from a marker as BG
% Get labels from GC
%     Find regions have a label.
%     Find Connected components and increment by CC founds before this label.
%     All cells should now have unique label
%
function fgp = fg_model(im, mask)
sz  = size(im);
fgp = zeros(sz(1), sz(2), max(mask(:)));
for i = 1:max(mask(:))
    fprintf('%d ', i)
    fg = bwlabel(mask==i);
    stats = regionprops(fg, 'Centroid');
    for j = 1:max(fg(:))
        clear idx vals tmp patch r
        idx         = find(fg == j);
        vals(:,1)   = im(idx);
        vals(:,2)   = im(idx+sz(1)*sz(2));
        vals(:,3)   = im(idx+sz(1)*sz(2)*2);
        model   = fitgmdist(vals, 1, 'RegularizationValue', 0.01, 'CovType', 'full', 'SharedCov', false);% covtype = 'diagonal';% 'full'
        
        w       = 20;
        cen     = round(stats(j).Centroid);
        r       = [max(1, cen(2)-w), min(sz(1), cen(2)+w), max(1, cen(1)-w), min(sz(2), cen(1)+w)];
        patch   = im(r(1):r(2), r(3):r(4), :);
        sz2     = size(patch);
        imv     = reshape(patch, sz2(1)*sz2(2), 3);
        tmp     = pdf(model, imv);
        tmp     = reshape(tmp, sz2(1), sz2(2));
        fgp(r(1):r(2), r(3):r(4), i)  = max(fgp(r(1):r(2), r(3):r(4), i), tmp);
    end
end
% necesary to avoid regions of a cell being assigned to another cell if the color within cell differs
for i = 1:max(mask(:))
    fgp(:,:,i) = max(fgp, [], 3);
end
end

function bgp = bg_model(im, mask)
sz  = size(im);
idx = find(mask>0);
vals(:,1) = im(idx);
vals(:,2) = im(idx+sz(1)*sz(2));
vals(:,3) = im(idx+sz(1)*sz(2)*2);

model   = fitgmdist(vals, 5, 'RegularizationValue', 0.01, 'CovType', 'diagonal', 'SharedCov', false);% covtype = 'diagonal';% 'full'
imv     = reshape(im, sz(1)*sz(2), 3);

bgp     = pdf(model, imv);
bgp     = reshape(bgp, sz(1), sz(2));
end