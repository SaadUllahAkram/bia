function layer = smooth_l1loss(name, bottom, weight)
if nargin <  3
    weight = 1;
end
layer = struct('name', name, 'type', 'SmoothL1Loss', 'bottom', {bottom}, 'loss_weight', weight);
end