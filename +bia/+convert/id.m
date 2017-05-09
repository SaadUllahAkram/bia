function [ids2, map] = id(ids, map)
% converts region ids in a frame to unique ids in a sequence and back
% 
% Has 2 modes:
% 
% Mode 1: Returns mapping needed to get/recover unique id of each region in a video
%     Inputs:
%         ids: cell array of stats
%     Outputs:
%         ids2: []
%         map: mapping to/from unique obj id
% 
% 
% Mode 2: Converts between unique id and id in a frame
%     Inputs:
%         ids: id of objs in 2 formats: [t, id_in_frame] OR [id_in_video]
%         stats: cell array of stats or mapping of ids
%     Outputs:
%         ids2: id of obj after conversion
%         map: map struct need for conversion
% 

if iscell(ids) % MODE 1
    ids2 = [];
    [map] = get_mapping(ids);
    return
end

% MODE 2
if iscell(map)
    map = get_mapping(map);
end

conversion = size(ids,2);
N = size(ids,1);
if conversion == 1
    ids2 = zeros(N, 2);
    for i=1:N
        ids2(i,:) = map.mat2stat(ids(i),:);
    end
elseif conversion == 2
    ids2 = zeros(N, 1);
    for i=1:N
        ids2(i) = map.stat2mat{ids(i,1)}(ids(i,2));
    end
end
end


function [map] = get_mapping(stats)
% get mapping to/from unique id to id in frame
T = length(stats);
num_regions = cellfun(@(x) length(x), stats);
start_idx = cumsum([0;num_regions]);% num of objs uptil current frame

stat2mat = cell(T,1); % mat{t}(region_id) -> row_num
mat2stat = zeros(max(num_regions), 2);% row_num -> [t region_id]
for t=1:T
    row_nums = start_idx(t)+1: start_idx(t+1);
    region_ids = [1:num_regions(t)]';
    mat2stat(row_nums, :) = [repmat(t,num_regions(t),1), region_ids];
    stat2mat{t}(region_ids) = row_nums;
end
map = struct('stat2mat',{stat2mat}, 'mat2stat', mat2stat);
end