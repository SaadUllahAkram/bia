function layer = accuracy(name, bottom)
layer = struct('name', name, 'type', 'Accuracy', 'bottom', {bottom});
end