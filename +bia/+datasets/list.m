function list(type)
if nargin == 0
    type = {'all'};
elseif ischar(type)
    type = {type};
end

if ismember('tra', type)
end
if ismember('seg', type)
end
if ismember('detect', type)
end
datasets = {'PhC-C2DH-U373','PhC-C2DL-PSC','Fluo-C2DL-MSC','DIC-C2DH-HeLa','Fluo-N2DH-GOWT1', 'Fluo-N2DL-HeLa',...
    'Hist-BM', 'PhC-HeLa-Ox',...
    'cpm',...% all 4 cancer types
    'cpm-gbm','cpm-hnsc','cpm-lgg','cpm-lung'};
for i=1:length(datasets)
    fprintf('%s\n', datasets{i})
end
end