function stats = extract(opts, stats, im)
% extracts features for each region in a given stats structure
% 
% Inputs:
%     opts.feature_set:
%         'celldetect' or 'oxford' (oxford cell detect features), 
%         'heid_count' (schiegg joint tracking #cells in a proposal prob.), 
%         'heid_cell' (schiegg joint tracking prob. of a proposal being a cell), 
%         'kth' (Magnusson, greedy shortest path)
%         'isbi' (isbi 16 joint tracking paper)
%     stats:    a cell array of stats of regions for each 't'
%     im:       a cell array of images for each 't'
% Outputs:
%     stats: same as input but with an extra field 'Features' added containing the extracted features
% 

opts_default = struct('feature_set', 'celldetect', 'verbose', 0);
opts         = bia.utils.updatefields(opts_default, opts);

feature_set = opts.feature_set;
verbose = opts.verbose;
T = length(stats);

if verbose
    fprintf('%d:: ', T)
    t_init = tic;
end
for t = 1:T
    if verbose
        fprintf('%d ', t)
    end

    if strcmp(feature_set, 'isbi')
        stats{t} = features_isbi15(stats{t}, im{t});
    elseif strcmp(feature_set, 'heid_count')
        stats{t} = features_heidelberg_count(stats{t}, im{t});
    elseif strcmp(feature_set, 'heid_cell')
        stats{t} = features_heidelberg_cell(stats{t}, im{t});
    elseif strcmp(feature_set, 'celldetect') || strcmp(feature_set, 'oxford')
        stats{t} = features_celldetect(stats{t}, im{t});
    end
end
if verbose
    fprintf('\nFeature Extraction took: %1.0f sec\n', toc(t_init))
end
end

function stats = features_celldetect(stats, im)
n = length(stats);
feats = cell(n,1);
parfor i=1:n
    feats{i} = bia.feats.celldetect(im, [], [], [], [], stats(i).PixelIdxList)';
end
for i=1:length(stats)
   stats(i).Features = feats{i};
end
end