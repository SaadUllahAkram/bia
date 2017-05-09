function validate_struct(st, val_type)
%     st: structure to be validated
%     val_type: 'prop', 'detect', 'tra', 'seg', 'gt'

fields_detect   = {'detect'};
fields_stats    = {'Area';'Centroid';'BoundingBox';'PixelIdxList'};
fields_tra      = {'detect'};
fields_seg      = fields_stats;
fields_props    = [fields_stats; {'Score'}];

if strcmp(val_type, 'gt')
    fields = {'sz','T','dim','foi_border','name'};
%     ,'seg','detect','tra'
elseif strcmp(val_type, 'detect')
elseif strcmp(val_type, 'tra')
elseif strcmp(val_type, 'seg')
% % a   = zeros(9);a(1) = 1;a(5)=3;
% % st  = regionprops(a,'area','pixelidxlist');
% % x   = num2cell([1 2 3]);
% % [st.x] = x{:};
end

% seg or props or detections can have no empty index
% detections all [x, y] > 0

% TRA:
% All empty indices shud have 'Area=0', PIDX=[], and other matlab's default emoty vals
% Check TRA info as well.