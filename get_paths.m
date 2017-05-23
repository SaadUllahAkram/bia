function paths = get_paths()
root = fullfile('', 'data');
bia.save.mkdir(root)

% dirs for softwares
paths.softwares.gurobi = '';% gurobi
paths.caffe.cpn = '';% cpn caffe
paths.ctc_eval = '';

% dirs with code: code paths
paths.code.matlab = fullfile(root, 'MATLAB');
paths.code.packages = '';

% dirs for reading untouched data: original downloaded data
paths.data.cpm16 = '';% cpn miccai challenge data
paths.data.ctc = '';% isbi cell tracking challenge data
paths.data.phc_hela_ox = '';% celldetect data
paths.data.hist_bm = '';% miccai: regression rf histological data

paths.data_mat.root = fullfile(root, 'datasets');% imported gt and image data
paths.data_mat.root1 = fullfile(root, 'datasets');% imported gt and image data
% dirs for saving data
paths.save.videos = fullfile(root, 'videos');

paths.temp = fullfile(root, 'temp_data');% where junk (temporary) data is saved
paths.save.cpn = fullfile(root, 'cpn_train');% cpn training
paths.save.cpn_res = fullfile(root, 'cpn_res');% cpn proposals
paths.save.track = fullfile(root, 'cpn_track');% cell tracking

% 
paths.save.baselines = '';% results of baseline methods
paths.save.oxford = '';% celldetect results
paths.save.kth = '';% kth tracking results
paths.save.unet = '';% unet results
paths.save.phc_gc = '';% graph cuts results


bia.save.mkdir(paths.temp)
bia.save.mkdir(paths.data_mat.root)
bia.save.mkdir(paths.data_mat.root1)


bia.save.mkdir(paths.temp)
bia.save.mkdir(paths.save.cpn)
bia.save.mkdir(paths.save.cpn_res)
bia.save.mkdir(paths.save.track)
end
