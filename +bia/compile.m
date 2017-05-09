function compile()

bia_path = mfilename('fullpath');
bia_path = fileparts(bia_path);

mex_dir = fullfile(bia_path,'+utils');
file_path = fullfile(mex_dir,'iou_mex.cpp');
% mex iou_mex.cpp
cmd = sprintf('mex -outdir %s %s',mex_dir, file_path);
eval(cmd)

end