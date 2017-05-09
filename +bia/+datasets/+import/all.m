function all()

% CPM
% http://www.miccai2017.org/satellite-events
% download from: http://miccai.cloudapp.net/competitions/57
bia.datasets.import.cpm();

% CTC: 2D
% download from: http://www.codesolorzano.com/Challenges/CTC/Datasets.html
bia.datasets.import.ctc('Fluo-N2DL-HeLa');
bia.datasets.import.ctc('Fluo-N2DH-GOWT1');
bia.datasets.import.ctc('PhC-C2DH-U373');
bia.datasets.import.ctc('PhC-C2DL-PSC');
bia.datasets.import.ctc('PhC-C2DL-PSC');
% 
bia.datasets.import.ctc('PhC-C2DL-PSC', [0 1]);% bg removed images
bia.datasets.import.ctc_fluo_hela_aug();% hela augmented data using watershed
bia.datasets.import.ctc_phc_u373(); % augmented data using unet and graph cuts

bia.datasets.import.hist_bm_miccai15();% import histological data
bia.datasets.import.phc_hela_ox_miccai12();% import celldetect data

% bia.datasets.import.ctc('Fluo-C2DL-MSC',0);
% bia.datasets.import.ctc('DIC-C2DH-HeLa',0);

% Hist-BM
% PhC-HeLa-Ox
end