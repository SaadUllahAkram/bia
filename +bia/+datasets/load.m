function [gt, ims, imo] = load(dataset, type, opts)
% Omit the seq number "-0x" to load data from both sequences.
% Inputs:
%     dataset: str containing dataset name, to specify seq, add "-0x", "-00" loads all sequences
%     type: 'gt' (only GT),
%           'im' or 'norm' (only Normalized images), 
%           'orig', (only orig images), 
%     opts:
% Outputs:
%     gt: ground truth
%     ims: cell array of normalized images
%     imo: cell array of untouched (original) images
% 

%% Version Info:
%     version: 0 :: Deafult
%     version: 1 :: 
%         Fluo-N2DL-HeLa : GT : Watershed used to augment GT
%         PhC-C2DL-PSC : norm : Background subtraction not used
% 

% bia.print.fprintf('*red', '\n\nLoaded: %s\n\n', dataset)
if nargin == 1 || isempty(type) || ischar(type)
    if nargin == 1; type = '';  end
    type = get_types(nargout, type);
end

if nargin < 3
    opts = [];
elseif isnumeric(opts)
    error('Update old code')
end
opts_dafault = struct('scale',1,'segmented',0,'tracked',0,'pad',0,'time',[],'version',[0 0 0],'test',0);
opts = bia.utils.updatefields(opts_dafault, opts);

scale = opts.scale; % resizing factor
tracked = opts.tracked;% [0 or 1], only load frames which were tracked
segmented = opts.segmented;% 0: do nothing, 1: only load frames which have any segmented mask, 2: only load fully segmented frames
pad = opts.pad;
time = opts.time;
version = opts.version;% [gt im_norm im_orig]:: -> version: 0 (default), 1
test = opts.test;% test: 1 (load test set)

if test == 1
    test_str = 'test-';
else
    test_str = '';
end
if length(version) == 1; version = [version version version]; end
paths = get_paths();
path = paths.data_mat.root1;
[dataset, seq_num] = get_seq(dataset);

% load data
load_gt = (ismember('gt', type) || tracked || segmented);
load_norm = ismember('im', type) || ismember('norm', type);
load_orig = ismember('orig', type);

N = length(seq_num);
gt_seqs = cell(N,1);
imc_seqs = cell(N,1);
imo_seqs = cell(N,1);
for i=1:N
    data_name = sprintf('%s-%02d',dataset, seq_num(i));
    if load_gt
        path_gt = fullfile(path, version_dir(version(1)), sprintf('%s%s-GT.mat', test_str, data_name));
        if ~exist(path_gt, 'file')
            warning('data not found at: %s', path_gt);
            load_gt = false;
        elseif load_gt
            tmp = load(path_gt,'gt');
            if size(tmp.gt.sz, 1) < tmp.gt.T
                warning('loading old GT data ?')
               tmp.gt = upgrade_1_gt(tmp.gt);
            end
            gt_seqs{i} = tmp.gt;
        end
    end

    if load_norm
        path_norm = fullfile(path, version_dir(version(2)), sprintf('%s%s-norm.mat', test_str, data_name));
        [imc_seqs{i}, load_norm] = load_ims(path_norm, load_norm);
    end

    if load_orig
        path_orig = fullfile(path, version_dir(version(3)), sprintf('%s%s-orig.mat', test_str, data_name));
        [imo_seqs{i}, load_orig] = load_ims(path_orig, load_orig);
    end
end

% merge data
if load_gt
    gt = merge_gt(gt_seqs{:});
    gt.sz_orig = gt.sz;
else
    gt = [];
end
if load_norm
    ims = merge_imc(imc_seqs{:});
else
    ims = [];
end
if load_orig
    imo = merge_imc(imo_seqs{:});
else
    imo = [];
end
if scale ~=1
    [gt, ims] = resize_dataset(gt, ims, scale);
    [~, imo] = resize_dataset([], imo, scale);
end


if ~isempty(time)
    if ~isempty(time)
        if size(time,2) > 1
            time = time';
        end
        if ~isempty(ims)
            ims = ims(time);
        end
        if ~isempty(gt)
            gt = t_crop_gt(gt, time);
        end
    end
end

tracked = tracked && isfield(gt, 'tra');
segmented = segmented*isfield(gt, 'seg');

if tracked
    tlist_tra = find(gt.tra.tracked);
else
    tlist_tra = [];
end
if segmented == 1
    %tlist_seg = seg_frames(gt.seg.stats);
    tlist_seg = gt.seg.info(gt.seg.info(:,2)==1, 1);
    % tlist_seg = gt.seg.info(:,1);
elseif segmented == 2
    tlist_seg = gt.seg.info(gt.seg.info(:,3)==1, 1);
else
    tlist_seg = [];
end

if segmented > 0 && tracked
    tlist = intersect(tlist_tra, tlist_seg);
    if isempty(tlist)
        fprintf('No common frame in tracked and segmented GT, so using only segmented frames\n');
        tlist = tlist_seg;
    end
elseif tracked
    tlist = tlist_tra;
elseif segmented
    tlist = tlist_seg;
else
    tlist = [];
end

if ~isempty(tlist)
    if ~isempty(ims)
        ims = ims(tlist);
    end
    if ~isempty(gt)
        gt = t_crop_gt(gt, tlist);
    end
end


if exist('pad','var') && pad ~= 0
    if pad == -1
        pad = gt.foi_border;
    end
    for t=1:length(ims)
        ims{t}=padarray(ims{t},[pad pad],'symmetric');
    end
    
    gt.foi_border = gt.foi_border + pad;
    sz_old = zeros(gt.T, size(gt.T,2));
    for t=1:gt.T
        sz_old(t,:) = gt.sz(t,:);
        gt.sz(t, 1:2) = gt.sz(t, 1:2) + 2*pad;
    end

    % seg
    if isfield(gt, 'seg')
        for t=1:length(gt.seg.stats)
           mask = bia.convert.stat2im(gt.seg.stats{t}, sz_old(t,:));
           mask = padarray(mask,[pad pad],0);
           gt.seg.stats{t} = regionprops(mask, 'Area','BoundingBox','Centroid','PixelIdxList');
        end
    end
    % tra
    if isfield(gt, 'tra')
        for t=1:length(gt.tra.stats)
           mask = bia.convert.stat2im(gt.tra.stats{t}, sz_old(t,:));
           mask = padarray(mask,[pad pad],0);
           gt.tra.stats{t} = regionprops(mask, 'Area','BoundingBox','Centroid','PixelIdxList');
        end
        gt.tra.stats = bia.struct.fill(gt.tra.stats);
    end
    % det
    if isfield(gt, 'detect')
        for t=1:length(gt.detect)
            gt.detect{t} = gt.detect{t} + pad;
        end
    end
end

end


function ver_dir = version_dir(ver)
if ver == 0
    ver_dir = '';
else
    ver_dir = sprintf('v%d',ver);
end
end


function type = get_types(num_out, type)
% finds what data to loads
if isempty(type);   type = [];  end
if ischar(type)
    type = {type};
elseif ismember(num_out, [0 1])
    type = {'gt'};
elseif num_out == 2
    type = {'gt', 'im'};
elseif num_out == 3
    type = {'gt', 'im', 'orig'};
end
end


function [dataset, seq_num] = get_seq(dataset)
% finds which data parts to load
seq_num = str2double(dataset(end-1:end));
if isempty(seq_num) || isnan(seq_num) || seq_num == 73% 73 is here for PhC-C2DH-U373 dataset
    seq_num = [1,2];
elseif seq_num == 0
    seq_num = [1,2];
    dataset = dataset(1:end-3);
elseif seq_num > 0
    dataset = dataset(1:end-3);
end
end


function gt = t_crop_gt(gt, tlist)
gt.detect = gt.detect(tlist);
gt.T = length(tlist);
gt.tra.tracked = gt.tra.tracked(tlist);
gt.tra.stats = gt.tra.stats(tlist);

gt.sz = gt.sz(tlist,:);
gt.sz_orig = gt.sz_orig(tlist,:);
% seg_tlist = seg_frames(gt.seg.stats);
gt.seg.info = gt.seg.info(tlist,:);
gt.seg.stats = gt.seg.stats(tlist);

intervals = find_intervals(tlist);
% only correct if there is 1 consecutive tracked interval
of = 0;
for i=1:size(intervals,1)
    %t_min = min(tlist);
    t_min = intervals(i,1);
    t_max = intervals(i,2);
    gt.tra.info(gt.tra.info(:,2) >=t_min & gt.tra.info(:,2)<=t_max, 2) = gt.tra.info(gt.tra.info(:,2) >=t_min & gt.tra.info(:,2)<=t_max, 2) - t_min + 1 + of;
    gt.tra.info(gt.tra.info(:,3) >=t_min & gt.tra.info(:,3)<=t_max, 3) = gt.tra.info(gt.tra.info(:,3) >=t_min & gt.tra.info(:,3)<=t_max, 3) - t_min + 1 + of;

    % seg
    gt.seg.info(gt.seg.info(:,1)>=t_min & gt.seg.info(:,1)<=t_max,1) = gt.seg.info(gt.seg.info(:,1)>=t_min & gt.seg.info(:,1)<=t_max,1) - t_min + 1 + of;
    of = of + intervals(i,2) - intervals(i,1) + 1;
end

gt.tra.info(gt.tra.info(:,2) > gt.T,:) = [];
gt.tra.info(gt.tra.info(:,3) > gt.T,3) = gt.T;

gt.tra.kept = tlist;
end

function intervals = find_intervals(tlist)
j = 0;
tlist = [-1; tlist];
for i=1:length(tlist)-1
    if tlist(i+1) - tlist(i) == 1
        term{j} = tlist(i);
    else
        if j>0
            term{j} = tlist(i);
        end
        j = j+1;
        init{j} = tlist(i+1);
        term{j} = tlist(i+1);
    end
end
term{j} = tlist(end);
for i=1:j
   intervals(i,:) = [init{i} term{i}];
end
end

function tlist = seg_frames(stats)
tlist = find(arrayfun(@(x) sum([x{1}.Area] > 0) > 0, stats));
end


function gt = upgrade_1_gt(gt)
sz = gt.sz(1,1:2);
T = gt.T;
for t=1:T
   gt.sz(t,1:3) = [sz 1];
end
gt.tra.tracked = logical(gt.tra.tracked);
stats = gt.seg.stats;
info = gt.seg.info;
gt.seg.stats = cell(T,1);
gt.seg.info = zeros(T,3);
for t=1:gt.T
    gt.seg.info(t,1) = t;
    if ismember(t, info(:,1))
        gt.seg.stats{t} = stats{info(:,1) == t};
        gt.seg.info(t,2) = 1;
        if info(info(:,1)==t, 3)
            gt.seg.info(t,3) = 1;
        end
    end
end
gt.seg.stats = fill_empty_stats(gt.seg.stats, 2);

end


function stats = fill_empty_stats(stats, dim)
for t=1:length(stats)
    if isempty(stats{t})
        stats{t}(1).Area = 0;
        stats{t}(1).PixelIdxList = [];
        stats{t}(1).Centroid = [NaN*ones(1, dim)];
        stats{t}(1).BoundingBox = [0.5*ones(1, dim), zeros(1, dim)];
    end
end
end


function [ims, do_load] = load_ims(path, do_load)
if do_load
    if exist(path, 'file')
        tmp = load(path);
    else
        warning('data not found at: %s', path);
        do_load = false;
    end
end
if ~do_load
    ims = [];
    return
end
if isfield(tmp, 'ims')
    ims = tmp.ims;
elseif isfield(tmp, 'ims_orig')
    ims = tmp.ims_orig;
elseif isfield(tmp, 'imc')% to load old data
    ims = tmp.imc;
end
end