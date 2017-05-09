TO ADD A NEW DATASET:
1. Set its path in "get_paths()"
2. Add its name to "bia.datasets.list()" : contains names of datasets which can be loaded by "bia.datasets.load()" function
3. Add function to import it in dir: "bia.datasets.import.dataset_function()" : this file reads the original dataset and converts it into the standard format.
4. Add call to import function in: "bia.datasets.all()" : re-import all datasets

##############

data dir structure: 
"datasetname"-"sequence#"-norm.mat
"datasetname"-"sequence#"-GT.mat
"datasetname"-"sequence#"-orig.mat
Different versions of data can be loaded by specifying the version: the data is saved in: "vX" dir

##############

Datasets:
    PhC-HeLa-Ox: GT (Centroids), Segmentation Masks (Automatic)
    Hist-BM: GT (Centroids), Segmentation Masks (Automatic)
