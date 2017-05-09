function [stack, props] = tif(filePath, tList, zList, cList, props)
% ToDo: Update description to account for channels, returns data in order [y,x,z,c,t]
% ToDo: ALso update GUI
% ToDo: accept only 1 argument and return the image specified (filePath, img_num, props)
% 
% Reads the tif files. If file contains single 3D stack it reads it all.
% WARNING : When reading few slices, 'stack' will contain stacks in the order specified in 'zList'.
%
% Usage :
%         [~, props] = bia.read.tif(filePath, 0);             --> Reading just meta-data
%     [stack, props] = bia.read.tif(filePath);                --> Reading first 3D/2D stack
%     [stack, props] = bia.read.tif(filePath, [], [], []);    --> Reading first 3D/2D stack
%     [stack, props] = bia.read.tif(filePath,  t, [], props); --> Reading t-th stack from an already open file
%     [stack, props] = bia.read.tif(filePath, [], [], []);    --> Reading all 3D/2D stacks from a time series
%     [stack, props] = bia.read.tif(filePath,  5, [], props); --> Reading 5th 3D/2D stack  from a time series
%     [stack, props] = bia.read.tif(filePath,  5, 3:7, props);--> Reading 3rd-7th slice from the 5th 3D/2D stack from a time series
%
% Inputs:
%     filePath    : complete file path
%     tList       : stack # to be read -> missing (Reads 1st stack), [] (Reads all stacks)
%     zList       : slice # to be read -> missing or [] (Reads all slices)
%     props       : [] (reads the file info)
% Outputs:
%     stack [HxWxZxT]  : 2D/3D stacks (usually uint8 or uint16)
%     props.{T,Z,H,W,class, info} : Properties of file & info structure needed for reading further data
%

offset = 0; %todo (accept it as input): accept offset, incase the .tif was not saved properly
% todo: 1. Accept 'T', 'Z', 'offset', 'class', ''

if ~exist(filePath, 'file')
    % Try extension change in case it was miss-typed or missing
    [fFolder, fName, ~]= fileparts(filePath);
    fnew1 = [fFolder, fName, '.tif'];
    fnew2 = [fFolder, fName, '.tiff'];
    if exist(fnew1, 'file') && exist(fnew2, 'file')
        fprintf('File Extension not specified: 2 files exist, specify extension\n')
    elseif exist(fnew1, 'file')
        filePath = fnew1;
        fprintf('File Extension not specified: Using .tif\n')
    elseif exist(fnew2, 'file')
        filePath = fnew2;
        fprintf('File Extension not specified: Using .tiff\n')
    else
        fprintf('File Missing : %s\n', filePath);
    end
    clear fnew1 fnew2 fFolder fName
end

%% Get file Props
if nargin < 4 || isempty(props)
    info        = imfinfo(filePath);
    % Handle cases where .tif does not have 'ImageDescription' field
    if ~isfield(info(1), 'ImageDescription')
        txt         = 'noinfoavailable';
    else
        txt         = info(1).ImageDescription;
    end
    T           = extractT(txt);
    Z           = extractZ(txt);
    C           = extractC(txt);
    if Z == 0
        Z       = numel(info);
        if Z > 300
           fprintf('Z:%d was too high, it is being capped at 200\n***********************************\n', Z)
           Z = 300;
        end
    end
%     fprintf('T:%d, Z:%d, <- %s\n', T, Z, filePath);
    props.info   = info;
    props.Z      = Z;
    props.T      = T;
    props.C      = C;
    
    props.bits    = info(1).BitsPerSample;
    if props.bits == 8
        props.class = 'uint8';
    elseif props.bits == 16
        props.class = 'uint16';
    end
    props.H       = info(1).Height;
    props.W       = info(1).Width;
    props.XRes    = info(1).XResolution;
    props.YRes    = info(1).YResolution;
end

%% Read File
if nargin < 4 || isempty(cList)
    cList = 1:props.C;
end
if nargin < 3 || isempty(zList)
    zList = 1:props.Z;
end
if nargin < 2
    tList = 1;
end
if isempty(tList)
    tList = 1:props.T;
end
if tList == 0 % not reading any image data
    stack = 0;
else % read the selected images
    stack = zeros(props.H, props.W, length(zList), length(tList), props.class);
    for i=1:length(tList)
        t = tList(i);
        for j=1:length(zList)
            for c = 1:length(cList)
                z                   = zList(j);
                ch                  = cList(c);
                idx                 = (t-1)*props.Z + z + offset + props.T*props.Z*(ch-1);
                stack(:, :, j, c, i)   = imread(filePath, idx, 'Info', props.info);
            end
        end
    end
end
end

%% Checks for 'T' value
function T = extractT(txt)
    labels  = {'SizeT="', 'frames='}; % identifiers for 'T' in metadata
    T       = findValues(txt, labels, 1);
end

%% Checks for 'Z' value
function Z = extractZ(txt)
    labels  = {' SizeZ="', 'slices='};
    Z       = findValues(txt, labels, 0);
end

%% Checks for 'C' value
function C = extractC(txt)
    labels  = {'channels='};
    C       = findValues(txt, labels, 1);
end

%% Find the labels and their adjacent number
function V_Final = findValues(txt, labels, V)
% Inputs:
%     txt     : string
%     labels  : cell containing identifier strings
%     V       : default value

default = V;
numL    = length(labels);
V       = default*ones(1, numL);
for i=1:numL
    idx{i}     = strfind(txt, labels{i});
    if ~isempty(idx{i})
        V(i)       = sscanf(txt(idx{i}(1) + length(labels{i}):end), '%d', 1);
    end
end

% validation
uniqV          = unique(V);
if length(uniqV) == 1
    V_Final = uniqV;
%     V_Final = default;
%     assert(uniqV == default)
else
    uniqV(uniqV == default)   = [];
    if length(uniqV) > 1
        for i=1:numL
            if ~isempty(idx{i})
                fprintf('Identifier: %d :%s, Value:%d, str:%s\n', i, labels{i}, V(i), txt( max(1, idx{i}(1))-5 : min(length(txt), idx{i}(1) + length(labels{i}) + 5)))
            end
        end
        error('Multiple values found for T or Z')
    else
        V_Final = uniqV;
    end
end
end
