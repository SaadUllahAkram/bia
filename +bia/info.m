%% Package Structure
% 
% * *metrics:* functions used for evaluation of detection, segmentation and tracking
% * *datasets:* functions needed to import, load, merge, etc datasets
% * *convert:* function used to transform bboxes, pixels, masks, etc
% * *prep:* functions used to preprocess images
% * *draw:* functions used to draw bbox, centroids, masks in images
% * *plot:* functions used to plot bboxes, centroids, masks, tracks, etc.
% 

%% Metrics
% * *Tracking*
% * CTC: TRA
% * MOTA:
% 
% * *Proposals* -> Using seg masks, bbox, tra markers
% * AP - Precision-Recall curve
% * AR - Recall-IoU curve
% 
% * *Detection* -> Using seg masks, bbox, tra markers
% * F1-Score
% * Precision
% * Recall
% * CellDetect Metrics
% 

%% Data Structures
%% Common Structure
% Common structure shared by: *segmentation, proposals and tracking* results.
% For *segmentation and proposals* this structure is the only thing needed.
%
% x. Column cell array with 1 cell per time frame
%
% x. Within each cell, a struct with following fields
%
% * .Area
% * .Centroid
% * .BoundingBox
% * .PixelIdxList
% 
% OPTIONAL:
% 
% * .PixelValues
% * .PixelList: [x,y,z of each pixel]
% * .Class: In case there are multiple cell classes available
% * .Score: Probabilty of the region
% * .Features:
% 
%% *Detection:*
% x. Column array of cells with each cell containing [x y z(in case of 3D)] pos of a cell in each row
% 
%% *Tracking:*
% tra.stats
%    * Cell ID (index in struct) across time remains same.
%    * A matrix keep track of events. [track_id, t_start, t_end, parent_id]
% tra.info: same format as in GT
% 
% Segmentation:
% 
%% GT
% 
% * .sz (size of a single stack)
% * .T
% * .foi_border: Field of Interest
% * .dim: 2 (2D)/3 (3D)
% * .name: "whole seq" previously were 2 strings "dataset" and "seq_num"
% * .tra.tracked: 1xT: 1(cells were tracked in that frame), 0(no tracking data for the frame)
% * .tra.stats
% * .tra.info: each row: [1:track_id, 2:t_start, 3:t_end, 4:parent_id, 5:left_or_died [0:undetermined, 1:died, 2:left]], parent_id==-1 --> uncertain
% if it has a parent or not, used when merging two videos from same sample but without mitosis annotation for 1st frame in 2nd video
% * .seg.stats
% * .seg.info: each row: [1:t, 2:dim_flag(0 [whole stack (2d/3d) segmented], >0 (slice in 3D)), 3:all_cells_segmented (0: only few cells segmented, 1:all cells segmented)]
% * .detect: same as detections above
