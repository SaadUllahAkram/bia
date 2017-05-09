function gt = merge_gt(varargin)
% combine GT data from 2 sequences. (CTC data mainly)
% update t-stamps of 2nd seq

gt                = varargin{1};
gt.name           = varargin{1}.name;
gt.T              = sum(cellfun(@(x) x.T, varargin));
N                 = length(varargin);
if N > 1
    gt.split = 0;
end
for i=2:N
   gt.sz = [gt.sz; varargin{i}.sz];
end

if isfield(gt, 'tra')
    gt.tra.stats    = cell(0);
    gt.tra.info     = [];
    gt.tra.tracked  = logical([]);
    t_init          = 0;
    for i=1:N
       tra_counts(i) = max(varargin{i}.tra.info(:,1));
    end
    tra_counts_cumsum = cumsum([0, tra_counts]);
    
    for i=1:N
        gt.tra.tracked = [gt.tra.tracked; varargin{i}.tra.tracked];
        
       info_updated = varargin{i}.tra.info;
       info_updated(:,2:3) = info_updated(:,2:3)+t_init;
       info_updated(:,1) = info_updated(:,1)+tra_counts_cumsum(i);
       info_updated(info_updated(:,4)>0, 4) = info_updated(info_updated(:,4)>0, 4)+tra_counts_cumsum(i);
       if t_init~=0
            info_updated(info_updated(:,4)==0, 4) = -1;% uncertain if it has a parent or not
       end
       gt.tra.info = [gt.tra.info; info_updated];
       
       % change idx of stats
       st = varargin{i}.tra.stats;
       clear st2
       for t=1:varargin{i}.T
           for k=length(st{t}):-1:1
                u = k + tra_counts_cumsum(i);
                st2{t,1}(u,1) = st{t}(k);
           end
           
       end
       st2 = bia.struct.fill(st2);
       gt.tra.stats(end+1 : end+ length(varargin{i}.tra.stats), 1) = st2;
       
       t_init = t_init+varargin{i}.T;
    end
end
if isfield(gt, 'seg')
    gt.seg.stats = cell(0);
    gt.seg.info  = [];
    t_init = 0;
    for i=1:N
       gt.seg.stats(end+1 : end+ length(varargin{i}.seg.stats), 1) = varargin{i}.seg.stats;
       info_updated = varargin{i}.seg.info;
       info_updated(:,1) = info_updated(:,1)+t_init;
       gt.seg.info = [gt.seg.info; info_updated];
       t_init       = t_init+varargin{i}.T;
    end
end
if isfield(gt, 'detect')
    gt.detect = cell(0);
    for i=1:N
       gt.detect(end+1 : end+length(varargin{i}.detect), 1) = varargin{i}.detect;
    end
end
end