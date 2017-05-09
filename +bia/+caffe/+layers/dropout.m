function layer = dropout(name, bottom, ratio)

layer = struct('name',name,'type','Dropout','bottom',bottom,'top',bottom,'dropout_param',struct('dropout_ratio',ratio));
end