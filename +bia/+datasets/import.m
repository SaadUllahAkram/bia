function import()

% import_phc_hela_ox_miccai12()
% import_hist_bm_miccai15()
% for k={'PhC-C2DH-U373','PhC-C2DL-PSC','Fluo-C2DL-MSC','DIC-C2DH-HeLa','Fluo-N2DH-GOWT1', 'Fluo-N2DL-HeLa'}
for k={'PhC-C2DL-PSC','PhC-C2DH-U373','Fluo-N2DH-GOWT1', 'Fluo-N2DL-HeLa'}%,'PhC-C2DL-PSC','Fluo-C2DL-MSC','DIC-C2DH-HeLa','Fluo-N2DH-GOWT1', 'Fluo-N2DL-HeLa'}
    import_ctc_isbi15(k{1}, [0 0 0]);
end

end