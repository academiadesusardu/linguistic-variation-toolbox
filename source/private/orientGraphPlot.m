function graphPlot = orientGraphPlot(graphPlot, nodeTable, firstCategory, secondCategory)
%ORIENTGRAPHPLOT Given a graph plot, orient it in such a way that the first
%and second categories are aligned in the middle.

% Copyright 2023 Acadèmia de su Sardu APS

[angle, ~] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory);
graphPlot = rotateGraphPlot(graphPlot, angle);
[~, centreCoords] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory);
graphPlot = centerGraphPlot(graphPlot, centreCoords);
end


function tf = iIsCategory(allData, category)
tf = cellfun(@(e) any([e.Category]==category), allData.Attributes);
end


function tf = iIsCategoryReferenceOfCategory(allData, category)
tf = cellfun(@(e) any([e.Category]==category & [e.IsCategoryReference]), allData.Attributes);
end


function baricentre = iComputeCategoryBaricentre(allData, category)
categorySelector = iIsCategory(allData, category);
baricentre = [mean(allData.X(categorySelector), "all"), ...
    mean(allData.Y(categorySelector), "all")];
end


function width = iComputeWidth(lims)
width = diff(lims);
end


function [angle, centreCoords] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory)
% Compute the centre coordinates and rotation angle given the input data
plotData = table(graphPlot.XData', graphPlot.YData', graphPlot.NodeLabel', ...
    VariableNames={'X', 'Y', 'Name'});
allData = join(plotData, nodeTable, Keys={'Name'});

plotAxes = graphPlot.Parent;
xWidth = iComputeWidth(xlim(plotAxes));

firstCategoryReferenceCoords = iComputeCategoryReferenceCoords(allData, firstCategory);
secondCategoryReferenceCoords = iComputeCategoryReferenceCoords(allData, secondCategory);

if ~isempty(firstCategoryReferenceCoords) && isempty(secondCategoryReferenceCoords)
    [angle, centreCoords] = iComputeCenterAndRotationWrtSingleCategory( ...
        firstCategoryReferenceCoords, ...
        allData, ...
        firstCategory, ...
        xWidth/4, pi);
elseif isempty(firstCategoryReferenceCoords) && ~isempty(secondCategoryReferenceCoords)
    [angle, centreCoords] = iComputeCenterAndRotationWrtSingleCategory( ...
        secondCategoryReferenceCoords, ...
        allData, ...
        secondCategory, ...
        -xWidth/4, 0);
elseif ~isempty(firstCategoryReferenceCoords) && ~isempty(secondCategoryReferenceCoords)
    [angle, centreCoords] = iComputeCenterAndRotationWrtBothCategories( ...
        firstCategoryReferenceCoords, ...
        secondCategoryReferenceCoords);
else
    error("Invalid specification of references in the plot");
end
end


function [angle, centreCoords] = iComputeCenterAndRotationWrtSingleCategory(categoryReferenceCoords, allData, category, coordsBias, angleBias)
% Compute the coordinates of the new centre and the rotation angle when you
% want to centre wrt a single category.
categorBaricentre = iComputeCategoryBaricentre(allData, category);

betweenBaricentreCoords = categorBaricentre-categoryReferenceCoords;
[theta, ~] = cart2pol(betweenBaricentreCoords(1), betweenBaricentreCoords(2));

centreCoords = categoryReferenceCoords;
centreCoords(1) = centreCoords(1)+coordsBias;
angle = -theta+angleBias;
end


function [angle, centreCoords] = iComputeCenterAndRotationWrtBothCategories(firstCategoryReferenceCoords, secondCategoryReferenceCoords)
% Compute the coordinates of the new centre and the angle of rotation when
% centering wrt both categories.
betweenCategoryReferenceCoords = secondCategoryReferenceCoords-firstCategoryReferenceCoords;
centreCoords = firstCategoryReferenceCoords+betweenCategoryReferenceCoords./2;
[theta, ~] = cart2pol(betweenCategoryReferenceCoords(1), betweenCategoryReferenceCoords(2));
angle = -theta;
end


function categoryReferenceCoords = iComputeCategoryReferenceCoords(allData, category)
% Given the data, compute the coordinates of the category references.
categoryReferenceCoords = [];
categoryReferenceIndex = find(iIsCategoryReferenceOfCategory(allData, category));

if numel(categoryReferenceIndex)==1
    categoryReferenceCoords = [allData.X(categoryReferenceIndex), allData.Y(categoryReferenceIndex)];
end
end