function [stats, M] = mser(opts, im)
% 
% Inputs:
%     opts: settings
%     im: UINT8 image
% Outputs:
%     stats: mser region stats
%     M: counts of props containing each pixel
% 

bia.add_code('vlfeat')
opts_default    = struct('mser_type', 1, 'delta', 1, 'area_range', [10 10000], 'area_var', 0.25, 'nms_overlap', 0.2, 'BrightOnDark', 1, 'DarkOnBright',0, ...
    'ext_feat_set', 2, 'use_parallel', 1, 'create_mask', 0);
opts            = bia.utils.updatefields(opts_default, opts);

mser_type       = opts.mser_type;% 1-> vlfeat, 2-> Matlab
delta           = opts.delta;%
area_range      = opts.area_range;
area_var        = opts.area_var;
%   area_var -> MaxVariation:: [0.25] = abs(R2 -R1)/R1, Rx are area of regions and R1 always has smaller area.
%       Set the maximum variation (absolute stability score) of the regions.
%       reducing it reduces num of regions:
%       Increasing this value returns a greater number of regions, but they may be less stable. Stable regions are very similar in size over varying intensity thresholds.
nms_overlap     = opts.nms_overlap;
%   nms_overlap -> MinDiversity:: [0.2]
%       Set the minimum diversity of the region. When the relative area variation of two nested regions is below this threshold, then only the most stable one is selected.
%       Increasing it causes the returned regions (much fewer regions are returned) to have smaller overlap, small values lead to very large overlap between them: use bboxes to check
%       similar to non-maximal suppression
% http://www.vlfeat.org/api/mser-fundamentals.html

BoD             = opts.BrightOnDark;
DoB             = opts.DarkOnBright;
ext_feat_set    = opts.ext_feat_set;
create_mask     = opts.create_mask;

num_pixels  = numel(im);
sz          = size(im);

if mser_type == 1
    vl_regions = vl_mser(im, 'BrightOnDark', BoD, 'DarkOnBright', DoB, 'Delta', delta, 'MinArea', area_range(1)/num_pixels, 'MaxArea', area_range(2)/num_pixels, 'MaxVariation', area_var, 'MinDiversity', nms_overlap);
    PixelIdxList = cell(length(vl_regions), 1);
    parfor i=1:length(vl_regions) %x=vl_regions'
        PixelIdxList{i}     = double(sort(unique(vl_erfill(im, vl_regions(i)))));
    end
    % create a connected object struct and then pass it to regionprops to get props for each object
    CC = struct('Connectivity', 8, 'NumObjects', length(vl_regions), 'ImageSize', sz, 'PixelIdxList', {PixelIdxList});
else
    %     http://se.mathworks.com/help/vision/ref/detectmserfeatures.html#namevaluepairarguments
    %     ThresholdDelta : delta in percentage of data type value range
    [~, CC] = detectMSERFeatures(im, 'ThresholdDelta', delta*100/255, 'RegionAreaRange', area_range, 'MaxAreaVariation', area_var);
    % plot(regions, 'showPixelList', false, 'showEllipses', true);
end

if create_mask
    M = zeros(sz);
    for i=1:length(vl_regions) %x=vl_regions'
        M(CC.PixelIdxList{i}) = M(CC.PixelIdxList{i}) + 1;
    end
else
    M = [];
end

if ext_feat_set == 1
    stats           = regionprops(CC, im, 'MinIntensity', 'MeanIntensity', 'MaxIntensity', 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList', 'Eccentricity', 'Solidity', 'Extent', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter', 'Orientation');
elseif ext_feat_set == 2
    stats           = regionprops(CC, 'Area', 'BoundingBox', 'Centroid', 'PixelIdxList');
end


end