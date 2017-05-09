function [gt, ims] = resize_dataset(gt, ims, scale)
% resize GT data and images. (CTC data mainly)

if scale == 1
    return
end

if ~isempty(ims)
    for t=1:length(ims)
        ims{t} = imresize(ims{t}, scale);
    end
end

if ~isempty(gt)
    if isfield(gt, 'tra')
        gt.tra.stats = bia.struct.resize(gt.tra.stats, scale, gt.sz, 0);
    end
    
    if isfield(gt, 'seg')
        gt.seg.stats = bia.struct.resize(gt.seg.stats, scale, gt.sz, 0);
    end

    if isfield(gt, 'detect')
        for t=1:gt.T
            gt.detect{t} = round(gt.detect{t}*scale);
        end
    end
    
    for t=1:gt.T
        mask = imresize(zeros(gt.sz(t, :)), scale, 'nearest');
        gt.sz(t,:) = [size(mask,1), size(mask,2), size(mask,3)];
    end
    
    if isfield(gt, 'foi_border')
         gt.foi_border = round(gt.foi_border*scale);
    end
%     clear mask
%     gt.cents = cell2mat(cellfun(@(x, y) [bia.convert.centroids(x), y*ones(sum([x.Area]>0), 1)], gt.tra.stats(1:gt.T), num2cell(1:gt.T), 'UniformOutput', false)');% get gt centroids
end
end