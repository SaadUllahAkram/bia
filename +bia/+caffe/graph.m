% function graph(net)
% creates the graph given a network

% http://caffe.berkeleyvision.org/tutorial/layers.html

g=digraph;
nn = net.layers;
N = length(nn);

for i=1:N
    if isfield(nn{i}, 'bottom')
        if iscell(nn{i}.bottom)
            for k=1:length(nn{i}.bottom)
                g = addedge(g,nn{i}.bottom{k},nn{i}.name);
            end
        else
            g = addedge(g,nn{i}.bottom,nn{i}.name);
        end
    end
end

plot(g,'layout','subspace')
% end