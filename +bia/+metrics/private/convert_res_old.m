function [seg, bbox, map] = convert_res_old(seg_res)
% convert standard struc to old 'bbox' and 'seg' variables
if size(seg_res,1) == 1
    seg_res = seg_res';
end
for t=1:length(seg_res)
    st = seg_res{t};
    if size(st,1) == 1
        st = st';
    end
    if ~isempty(st)
        aa = [st(:).Area];
        st(aa==0) = [];
        seg_res{t,1} = st;
        map{t,1} = [t*ones(sum(aa>0), 1), find(aa>0)'];
    else
        map{t,1} = [];
    end
end
ii = arrayfun(@(x) isempty(x{1}), seg_res);
seg_res2 = seg_res; seg_res2(ii) = [];
map2 = map; map2(ii) = [];
seg     = cell2mat(seg_res2);
map     = cell2mat(map2);

tlist   = [];
for t = 1:length(seg_res)
    tlist(end+1:end+length(seg_res{t}),1) = t;
end
bb = bia.convert.bb(seg, 's2m');
if isfield(seg, 'Score')
    bbox    = [bb, [seg(:).Score]', tlist];
else
    % warning('Score field is missing')
    bbox    = [bb, ones(size(tlist)), tlist];
end