function [mitosis_ids, mitosis_t, exit_ids, exit_t, enter_ids, enter_t] = events(opts, info)
% 
% Inputs:
%     info: [track_id, t_start, t_end, parent, left_or_died], parent == 0, if there is no parent, left_or_died == 0, if undetermined
% Outputs: [all are ROW vectors]
%     mitosis_ids : ids of cells that under-went mitosis
%     mitosis_t   : time at which mitosis occurred [last frame in which parent was present]
%     exit_ids    : ids of cells that under-went mitosis
%     exit_t      : time at which cell was last seen
%     enter_ids   : ids of cells which entered from outside
%     enter_t     : time at which cell was first seen
% 

opts_default = struct('use_end_frames',0,'use_mitosis',1);
opts = bia.utils.updatefields(opts_default, opts);
use_end_frames = opts.use_end_frames;% use cells in 1st/last frame as entering/exiting cells
use_mitosis = opts.use_mitosis;% 1-> ignore parents/daughters as entering/exiting, 0 -> use daughters as entering and parents as exiting cells

if isempty(info)
    mitosis_ids = [];
    mitosis_t = [];
    exit_ids = [];
    exit_t = [];
    enter_ids = [];
    enter_t = [];
    return
end

parents = unique(info(:, 4))';
parents(parents==0) = []; %ids of parents & get rid of no parent (0)

idx_parents = ismember(info(:,1), parents); % get logical array, 1 where parents is present
mitosis_ids = info(idx_parents, 1)'; % ids of parents
mitosis_t   = info(idx_parents, 3)'; % last 't' of parents

if use_end_frames
    exit = info(:, 1)'; % ids of candidates for exit/death
    enter_rows = info(:,1)>0;% select all rows
else
%     t_start = find(gt.tra.tracked,1,'first');
%     t_end = find(gt.tra.tracked,1,'last');
    t_start = min(info(:, 2));
    t_end = max(info(:, 3));
    exit = info(info(:,3) <  t_end, 1)'; % ids of candidates for exit/death
    enter_rows = info(:,2)>t_start; % ignore cells in 1st frame as they cant have a parent
end

if use_mitosis
    exit = setdiff(exit, parents)'; % ignore parents
    enter_rows = enter_rows & info(:,4) == 0;% ignore daughters
end

idx_exit = ismember(info(:,1), exit); %
exit_ids = info(idx_exit, 1)';
exit_t   = info(idx_exit, 3)';

enter_ids   = info(enter_rows, 1)';
enter_t     = info(enter_rows, 2)';

[mitosis_ids, mitosis_t] = sort_loc(mitosis_ids, mitosis_t);
[exit_ids, exit_t] = sort_loc(exit_ids, exit_t);
[enter_ids, enter_t] = sort_loc(enter_ids, enter_t);

end

function [ids, t] = sort_loc(ids, t)
[t, idx] = sort(t);
ids = ids(idx);
end