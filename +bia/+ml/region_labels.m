function stats = region_labels(opts, stats, gt_cents, sz)
% Counts # of GT cells in each region
% 
% Inputs:
%     opts: settings
%     stats: stats object for which feats have to be extracted
%     gt_cents: cell array containing GT marker centroids
% Outputs:
%     stats: stats object with 'label' field added. label contains the number of markers inside the region
%

opts_default = struct('im',[],'max_labels',Inf,'use_seg',1);
opts = bia.utils.updatefields(opts_default, opts);
im   = opts.im;% pass the image to visualize the labels
max_labels = opts.max_labels;% to cap the labels, 
use_seg = opts.use_seg;

for t=1:length(stats)
    if isempty(gt_cents)
        N = length(stats{t});
        for i=1:N
            stats{t}(i).Label = -1;
        end
    elseif use_seg
        N = length(stats{t});
        gt_cent = gt_cents{t};
        if isempty(gt_cent)
            num_cells = -ones(N, 1);
            for i=1:N
                stats{t}(i).Label = num_cells(i);
            end
        else
            num_cells = zeros(N, 1);
            idx_gt = sub2ind(sz(t,1:2), gt_cent(:,2), gt_cent(:,1));
            idx_gt = sort(idx_gt);
            for i=1:N
                [~,~,in] = bia.utils.iou_mex(idx_gt, stats{t}(i).PixelIdxList);
                num_cells(i) = in;
                if in > max_labels
                    in = 0;
                end
                stats{t}(i).Label = in;
            end
        end
    else
        [rects, idx] = bia.convert.bb(stats{t}, 's2r');% convert bbs to rect
        gt_cent = gt_cents{t};
        if isempty(gt_cent)
            num_cells = -ones(size(rects, 1), 1);
        else
            num_cells = zeros(size(rects, 1), 1);
            parfor i=1:size(rects, 1)
                r  = rects(i, :);
                in = r(1) <= gt_cent(:,2) & r(2) >= gt_cent(:,2) & r(3) <= gt_cent(:,1) & r(4) >= gt_cent(:,1);% finds which gt marker are inside the bbox
                num_cells(i) = sum(in);
            end
            num_cells(num_cells > max_labels) = 0;
        end

        for i=1:size(rects, 1)
            stats{t}(idx(i)).Label = num_cells(i);
        end        
    end

    if ~isempty(im)
        s = stats{t};

        s0  = s([s.Label] == 0);
        im0 = bia.draw.boundary(struct('cmap','b'), im{t}, s0);
        
        s1 = s([s.Label] == 1);
        im1 = bia.draw.boundary(struct('cmap','g'), im0, s1);

        s2 = s([s.Label] > 1);
        im2 = bia.draw.boundary(struct('cmap','r'), im1, s2);
        imshow(im2)
    end
end
end
