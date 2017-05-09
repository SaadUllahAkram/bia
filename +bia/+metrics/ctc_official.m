function ctc_official(gt, res_stats, res_info)
% Uses official CTC code to evaluate results
% 
% Usage: 
%     ctc_official(): downloads the CTC software
% 
% Inputs:
%     gt: ground truth, must have 'tra' & 'seg' fields
%     res_stats: tracked stats
%     res_info: track lineage/start/end relationships
% 

seq = '01';
paths = get_paths();
root = fullfile(paths.ctc_eval);
dir_tmp = fullfile(root, 'tmp');% where temp data is saved

bia.save.mkdir(root);
if isunix
    dir_soft = fullfile(root, 'Linux');
    ext = '';
    cmd = @(e, s) sprintf('./%s %s %s', e, dir_tmp, s);
else
    dir_soft = fullfile(root, 'Win');
    ext = '.exe';
    cmd = @(e, s) sprintf('"%s" "%s" %s', e, dir_tmp, s);
end
tra_exe = ['TRAMeasure', ext];
seg_exe = ['SEGMeasure', ext];
tra_file = fullfile(dir_soft, tra_exe);
seg_file = fullfile(dir_soft, seg_exe);

if ~exist(tra_file, 'file') || ~exist(seg_file, 'file')
    cur_dir = pwd;
    cd(root)
    zip_file = websave('EvaluationSoftware.zip', 'http://ctc2015.gryf.fi.muni.cz/Public/Software/EvaluationSoftware.zip');
    unzip(zip_file, root)
    assert(exist(tra_file, 'file') && exist(seg_file, 'file'), 'CTC Software not found at: \n%s\n%s', tra_file, seg_file)
    if isunix
        cd(dir_soft)
        [~,~] = system(sprintf('chmod -x %s', tra_exe));
        [~,~] = system(sprintf('chmod -x %s', seg_exe));
    end
    cd(cur_dir)
end


if nargin == 0 || ~isfield(gt, 'tra') || ~isfield(gt, 'seg')
    return
end


if exist(dir_tmp, 'dir')
    warning('%s, already exist!', dir_tmp);
end
bia.save.mkdir(dir_tmp)


dir_gt_seg = fullfile(dir_tmp, [seq, '_GT'], 'SEG');
dir_gt_tra = fullfile(dir_tmp, [seq, '_GT'], 'TRA');
dir_res = fullfile(dir_tmp, [seq, '_RES']);
bia.save.mkdir(dir_gt_seg)
bia.save.mkdir(dir_gt_tra)
bia.save.mkdir(dir_res)

sz = gt.sz;
for t=1:gt.T
    % save GT .tif
    gt_tra_im = bia.convert.stat2im(gt.tra.stats{t}, sz(t,:));
    gt_tra_path = fullfile(dir_gt_tra, sprintf('man_track%03d.tif', t-1));
    imwrite(gt_tra_im, gt_tra_path);

    if sum([gt.seg.stats{t}.Area] > 0)
        gt_seg_im = bia.convert.stat2im(gt.seg.stats{t}, sz(t,:));
        gt_seg_path = fullfile(dir_gt_seg, sprintf('man_seg%03d.tif', t-1));
        imwrite(gt_seg_im, gt_seg_path);
    end
    
    % save RES .tif
    res_im = bia.convert.stat2im(res_stats{t}, sz(t,:));
    res_path = fullfile(dir_res, sprintf('mask%03d.tif', t-1));
    imwrite(res_im, res_path);
end

% save GT+RES .txt files
save_txt(fullfile(dir_gt_tra, 'man_track.txt'), gt.tra.info)
save_txt(fullfile(dir_res, 'res_track.txt'), res_info)

% call the official code
cur_dir = pwd;
cd(dir_soft)
[~,tra_txt] = system(cmd(tra_exe, seq));
[~,seg_txt] = system(cmd(seg_exe, seq));
cd(cur_dir);

fprintf('%s,  %s\n', tra_txt(1:end-1), seg_txt(1:end-1))
% import official results


% remove tmp dir and its contents
rmdir(dir_tmp, 's');
end


function save_txt(p, d)
% saves track info [id, t_start, t_end, parent_id]
d(:,2:3) = d(:,2:3)-1;
fid = fopen(p, 'w');
for i=1:size(d,1)
   fprintf(fid, '%d %d %d %d\n', d(i,1), d(i,2), d(i,3), d(i,4));
end
fclose(fid);
end