clear all
% A lot of the code for object extraction comes from the following source:
% https://stackoverflow.com/questions/30086895/extract-object-from-image-in-matlab

% Open every image in the dataset
files = dir('dataset/*.tif');
for file = files'
    fileName = file.name
    textIm = imread(strcat(file.folder, '/', file.name));

    % find threshold and change to binary image
    border = graythresh(textIm);
    textbw = ~im2bw(textIm, border);
    
    
    % remove noise with median filter
    textfilt = medfilt2(textbw,[7 7]);
    textfilt = bwareaopen(textfilt,4);

    
    % Use an absurdely large line structuring element oriented at 25 degrees
    % to make the a's stand out
    
    se = strel('line', 20 ,25);
    textfilt = imclose(textfilt, se);
    
    
    % Get a couple properties. Note the "Eccentricity"
    S = regionprops(textfilt, 'Area','Eccentricity','Centroid','BoundingBox');

    All_areas = vertcat(S.Area);

    
    % Find the largest element (i.e. the big a). We will use it to get its
    % eccentricity and fetch other a's.
    
    [MaxArea, MaxAreaIdx] = (max(All_areas(:)));
    
    % Get eccentricity of largest letter.
    RefEcc = S(MaxAreaIdx).Eccentricity;
    
    % Just concatenate everything. Easier to work with.
    All_Ecc = vertcat(S.Eccentricity);
    All_Centroids = vertcat(S.Centroid);
    All_BB = vertcat(S.BoundingBox);
    
    % Find elements that have the approximate eccentricity of the large a
    % found earlier. You can be more/less stringent and add more conditions here.
    
    PotA = find(All_Ecc > RefEcc*.8 & All_Ecc < RefEcc*1.2);
    
    %scatter(All_Centroids(PotA,1),All_Centroids(PotA,2),60,'r','filled');
    
    Content = All_BB(PotA(1),:);
    
    %Convert to grayscale
    textIm = rgb2gray(textIm);
    
    cropped = imcrop(textIm, Content);

    [lengthY, lengthX] = size(cropped);
    
    % Make the leaf extractions square by adding a margin to the top and
    % below, or to the sides
    if lengthX > lengthY
        marginHeight = round((lengthX - lengthY)/2);
    
        colorTop = double(textIm(1,1));
        colorBot = double(textIm(end,1));
        marginTop = zeros(marginHeight, lengthX) + colorTop;
        marginBot = zeros(marginHeight, lengthX) + colorBot;
    
        cropped = [marginTop; cropped; marginBot];
    end
    
    if lengthY > lengthX
        marginWidth = round((lengthY - lengthX)/2);
        
        colorLeft = double(textIm(1,1));
        colorRight = double(textIm(1, end));
        marginLeft = zeros(lengthY, marginWidth) + colorLeft;
        marginRight = zeros(lengthY, marginWidth) + colorRight;
    
        cropped = [marginLeft cropped marginRight];
    end
    
    % Resize to a 50x50 pixel image
    resized = imresize(cropped,[324 324]);
    
    % Save image
    imwrite(resized, strcat('prepared/',fileName));
end
