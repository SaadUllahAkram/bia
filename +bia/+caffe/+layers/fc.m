function layer = fc(name, bottom, num_fc, init_std)

layer = struct('name',name,'type','InnerProduct','bottom',bottom,'top',name,...
    'param', struct('lr_mult', 1), 'param2', struct('lr_mult', 2), ...
    'inner_product_param', struct('num_output', num_fc, ...
    'bias_filler', struct('type', 'constant', 'value', 0) )); % part missing
if isnumeric(init_std)
   layer.inner_product_param.weight_filler = struct('type', 'gaussian', 'std', init_std);
else
    layer.inner_product_param.weight_filler = init_std;
end
end