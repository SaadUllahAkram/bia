function x = celldetect(img, colorImg, edgeImg, gradImg, orientGrad, sel)
% code is from: http://www.robots.ox.ac.uk/~vgg/software/cell_detection/downloads/CellDetect_v1.0.tar.gz
% 
%Encodes a single MSER with the selected features.
%OUTPUT:
%   x =  feature vector
%INPUT:
%   im = image (UINT8)
%   sel = linear indexes of the MSER pixels in im
%   ell = Vector with the information of the ellipse fitted to the MSER
%   (VL_feat)
%   parms = structure indicating the different features and parameters
% 
% 
% Copyright (C) 2012 by Carlos Arteta
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
% 
parms = setFeatures();
parms.nFeatures = parms.nBinsArea*parms.addArea + 2*parms.addPos + (1)*parms.nBinsIntHist*parms.addIntHist + parms.nBinsDiffHist*parms.addDiffHist*parms.nDilationScales...
    + parms.nAngBins*parms.nRadBins*parms.addShape + parms.addBias + parms.addOrientation*parms.nBinsOrient + parms.addEdges + parms.addOrientGrad*parms.nBinsOrientGrad;  


mask = logical(false(size(img,1), size(img,2)));
mask(sel) = 1;
[Y,X] = find(mask == 1);
centroid = [mean(X) mean(Y)];
centroid = round(centroid);
%mask = bwmorph(mask, 'close');
x = zeros(1,parms.nFeatures);
pos = 1;

%get ROI
st = regionprops(logical(mask), 'BoundingBox');
x1 = round(max([1 st(1).BoundingBox(1)-(parms.nDilationScales*parms.nDilations+2)]));
y1 = round(max([1 st(1).BoundingBox(2)-(parms.nDilationScales*parms.nDilations+2)]));
x2 = round(min([size(mask,2) st(1).BoundingBox(1)+st(1).BoundingBox(3)+...
    parms.nDilationScales*parms.nDilations+2]));
y2 = round(min([size(mask,1) st(1).BoundingBox(2)+st(1).BoundingBox(4)+...
    parms.nDilationScales*parms.nDilations+2]));
maskROI = mask(y1:y2,x1:x2);
imgROI = img(y1:y2,x1:x2);

%--feature computation
numPixels = size(img,1)*size(img,2);
if parms.addArea
    x(pos) = numel(sel);
    pos = pos+1;
end

if parms.addPos
    x(pos:pos+numel(centroid)-1) = centroid;
    pos = pos+numel(centroid);
end

if parms.addIntHist
    intHist = hist(img(mask == 1),0:255/parms.nBinsIntHist:255-255/parms.nBinsIntHist);
    intHist = intHist/norm(intHist,2);
    x(pos:pos+parms.nBinsIntHist-1) = intHist;
    pos = pos+parms.nBinsIntHist;
    
    if ~isempty(colorImg)
        for layer = 1:size(colorImg,3)
            color = colorImg(:,:,layer);
            intHist = hist(color(mask == 1),0:255/parms.nBinsIntHist:255-255/parms.nBinsIntHist);
            intHist = intHist/norm(intHist,2);
            x(pos:pos+parms.nBinsIntHist-1) = intHist;
            pos = pos+parms.nBinsIntHist;
        end
    end
end

if parms.addDiffHist
    boundary = bwmorph(maskROI, 'remove');
    for i = 1:parms.nDilationScales
        border = boundary;
        dilatedMask = bwmorph(maskROI, 'dilate', i*parms.nDilations);
        borderBig = bwmorph(dilatedMask, 'remove');
        
        %Discard the regions that did not grow (against image borders)
        constrained = border == borderBig;
        border(border == constrained) = 0;
        borderBig(borderBig == constrained) = 0;
        clear constrained
        
        [~,distanceTransf] = bwdist(borderBig);
        
        borderPixels = border == 1;
        intensitiesIn = imgROI(borderPixels);
        intensitiesOut = imgROI(distanceTransf(borderPixels));
        differences =  abs(double(intensitiesIn) - double(intensitiesOut));
        diffHist = hist(differences,0:255/parms.nBinsDiffHist:255-255/parms.nBinsDiffHist);
        diffHist = diffHist/norm(diffHist,2);
        % To check, [a(:,1),a(:,2)]=ind2sub(size(im),distanceTransf(borderPixels))
        x(pos:pos+parms.nBinsDiffHist-1) = diffHist;
        pos = pos+parms.nBinsDiffHist;
    end
end

if parms.addShape || parms.addOrientation
    [bins,angle] = cpdh(maskROI, parms.nAngBins, parms.nRadBins);
    if parms.addShape
        x(pos:pos+length(bins)-1) = bins';
        pos = pos+length(bins);
    end
    if parms.addOrientation
        orientHist = histc(angle,-90:180/parms.nBinsOrient:90-180/parms.nBinsOrient);
        x(pos:pos+parms.nBinsOrient-1) = orientHist;
        pos = pos+parms.nBinsOrient;
    end
end

if parms.addEdges
    nEdges = numel(find(edgeImg(sel) == 1));
    nEdges = 100*nEdges/numPixels;
    x(pos) = nEdges;
    pos = pos + 1;
end

if parms.addOrientGrad
    binsOrientGrad = linspace(0,180,parms.nBinsOrientGrad);
    qOrientGrad = vl_binsearch(binsOrientGrad,orientGrad);
    wGrad = gradImg.*sqrt(parms.depthMap);
    sumOrientGrad = vl_binsum(zeros(1,parms.nBinsOrientGrad), wGrad(sel), qOrientGrad(sel));
    sumOrientGrad = sumOrientGrad/(numel(sel)*10);
    x(pos:pos+parms.nBinsOrientGrad-1) = sumOrientGrad;
    pos = pos+parms.nBinsOrientGrad;
end

x = x';
end

function parameters = setFeatures()
%To set the features and control for training/testing
%OUTPUT
%   parameters = strucutre with learning parameters
%------------------------------------------------------------------Features

eqHist = 0; %Equalize histogram
addArea = 1; %Adds area descriptor of the MSER
nBinsArea = 1;
areaBinType = 'log';%linear = 'lin', logarithmic = 'log'
minArea = 0.01/100;
maxArea = 2/100;
addIntHist = 1;%Adds intensity information
nBinsIntHist = 15; %Per color channel
addPos = 0; %Adds XY position
addDiffHist = 1; %Adds histogram of difference between MSER and its context
nBinsDiffHist = 8;
nDilations = 2;
nDilationScales = 2;
addShape = 1; %Adds shape descriptor
nAngBins = 12;
nRadBins = 5;
addOrientation = 0;
nBinsOrient = 8;
addEdges = 0;
addOrientGrad = 0;
nBinsOrientGrad = 10;
addBias = 0;
bias = 100;
jitterSize = 3; %Size (in pixels) of the jitter introduced to the annotations

parameters.addArea = addArea;
parameters.nBinsArea = nBinsArea;
parameters.minArea = minArea;
parameters.maxArea = maxArea;
parameters.addPos = addPos;
parameters.addIntHist = addIntHist;
parameters.nBinsIntHist = nBinsIntHist;
parameters.addDiffHist = addDiffHist;
parameters.nBinsDiffHist = nBinsDiffHist;
parameters.nDilations = nDilations;
parameters.nDilationScales = nDilationScales;
parameters.addShape = addShape;
parameters.nAngBins = nAngBins;
parameters.nRadBins = nRadBins;
parameters.addBias = addBias;
parameters.bias = bias;
parameters.eqHist = eqHist;
parameters.jitter = 1;
parameters.jitterSize = jitterSize;
parameters.areaBinType = areaBinType;
parameters.addOrientation = addOrientation;
parameters.nBinsOrient = nBinsOrient;
parameters.addOrientGrad = addOrientGrad;
parameters.nBinsOrientGrad = nBinsOrientGrad;
parameters.addEdges = addEdges;
end
