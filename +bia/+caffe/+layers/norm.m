function layer = norm(name, bottom)
layer = struct('name',name,'type','LRN','bottom',bottom,'lrn_param',struct('local_size',3,'alpha',0.00005,'beta',0.75,'norm_region','WITHIN_CHANNEL'));
end