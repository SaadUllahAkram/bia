function [gt, imc] = extract(gt, imc, tlist, rect)
% Extracts data from few selected frames
%
%     gt   : struct with the GT data
%     imc  : cell array of images
%     tlist: frames to be retained, [] or skipped -> select all frames
%     rect : to extract a small rectangle from the selected frames, [] or skipped -> extract whole frame
%

if nargin < 3
    tlist   = [];
end
if nargin < 4
    rect    = [];
end
if size(tlist,1) > 1
    tlist = tlist';
end

% extract frames
if ~isempty(tlist)
    if ~isempty(imc)
        imc  = imc(tlist);
    end
    if ~isempty(gt)
        gt.T = length(tlist);
        if isfield(gt, 'detect')
            gt.detect = gt.detect(tlist);
        end
        if isfield(gt, 'seg')
            gt.seg.stats = gt.seg.stats(tlist);
            gt.seg.info  = gt.seg.info(ismember(gt.seg.info(:,1), tlist), :);
        end
        if isfield(gt, 'tra')
            for i=1:length(tlist)-1
                if (tlist(i) ~= tlist(i+1)-1)
                    warning('frame #s should be consecutive for extracting tracking frames')
                end
            end
            gt.tra.stats = gt.tra.stats(tlist);
            gt.tra.tracked = gt.tra.tracked(1, tlist);
            del = [];
            del = [del; gt.tra.info(gt.tra.info(:,2)<tlist(1)   ,1)];
            del = [del; gt.tra.info(gt.tra.info(:,3)>tlist(end) ,1)];
            for t=1:gt.T
                gt.tra.stats(del) = [];
            end
            ids_old      = 1:max(gt.tra.info(:,1));
            ids_old(del) = [];
            m            = max(ids_old);
            for i=1:length(ids_old)
                gt.tra.info(gt.tra.info(:,1)==ids_old(i),1) = m+i;
                gt.tra.info(gt.tra.info(:,4)==ids_old(i),4) = m+i;
            end
            gt.tra.info(:,1) = gt.tra.info(:,1)-m;
            gt.tra.info(:,4) = gt.tra.info(:,4)-m;
            
            gt.tra.info  = gt.tra.info(ismember(gt.seg.info(:,1), tlist), :);
            gt.tra.info(gt.tra.info(:,2)<tlist(1),2) = 1;
            gt.tra.info(:,3) = gt.tra.info(:,3)-tlist(1)+1;
            gt.tra.info(gt.tra.info(:,3)>tlist(end),3) = gt.T;
        end
    end
end
% extract rect
if ~isempty(rect)
    r = rect;
    T = length(tlist);
    if ~isempty(imc)
        for t=1:T
            imc{t} = imc{t}(r(1):r(2), r(3):r(4), :);
        end
    end
    if ~isempty(gt)
        sz_orig = gt.sz;
        if isfield(gt, 'detect')
            for t=1:T
                rm = gt.detect{t}(:,1)<r(3) || gt.detect{t}(:,1)>r(4) || gt.detect{t}(:,2)<r(1) || gt.detect{t}(:,2)>r(2);
                gt.detect{t}(rm, :) = [];
            end
        end
        if isfield(gt, 'seg')
            for t=1:T
                st = crop_stats(gt.seg.stats{t}, sz_orig);
                aa = [st(:).Area];
                st(aa==0) = [];
                gt.seg.stats{t,1} = st;
            end
        end
        if isfield(gt, 'tra')
            active = zeros(max(gt.tra.info(:,1)), T);
            for t=1:T
                st = crop_stats(gt.tra.stats{t}, sz_orig);
                gt.seg.stats{t,1} = st;
                aa = [st(:).Area];
                active(1:length(aa),t) = aa>0;
            end
            del = find(sum(active,2) == 0);
            for t=1:gt.T
                gt.tra.stats(del) = [];
            end
            ids_old      = 1:max(gt.tra.info(:,1));
            ids_old(del) = [];
            m            = max(ids_old);
            for i=1:length(ids_old)
                gt.tra.info(gt.tra.info(:,1)==ids_old(i),1) = m+i;
                gt.tra.info(gt.tra.info(:,4)==ids_old(i),4) = m+i;
            end
            gt.tra.info(:,1) = gt.tra.info(:,1)-m;
            gt.tra.info(:,4) = gt.tra.info(:,4)-m;
            
            gt.tra.info  = gt.tra.info(ismember(gt.seg.info(:,1), tlist), :);
            gt.tra.info(gt.tra.info(:,2)<tlist(1),2) = 1;
            gt.tra.info(:,3) = gt.tra.info(:,3)-tlist(1)+1;
            gt.tra.info(gt.tra.info(:,3)>tlist(end),3) = gt.T;
        end
        gt.sz(1:2) = [r(2)-r(1)+1, r(4)-r(3)+1];
    end
end

end
function st = crop_stats(st1, sz_orig)
mask = bia.convert.stat2im(st1, sz_orig);
mask = mask(r(1):r(2), r(3):r(4), :);
st = regionprops(mask,'Area','Centroid','BoundingBox','PixelIdxList');
end

function rm_empty_tracks()

end