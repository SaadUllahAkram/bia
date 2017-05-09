function tracks_validate(stats)
% add code to check that there are no missing frames in tracks (stats)

assert(isfield(stats{1}, 'Area'))
assert(isfield(stats{1}, 'Centroid'))
assert(isfield(stats{1}, 'BoundingBox'))
assert(isfield(stats{1}, 'Centroid'))

for t=1:length(stats)
    assert(length(stats{t}) == length([stats{t}(:).Area]))
end
end