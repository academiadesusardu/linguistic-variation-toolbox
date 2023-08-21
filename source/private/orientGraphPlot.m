function graphPlot = orientGraphPlot(graphPlot, nodeTable, firstCategory, secondCategory)
%ORIENTGRAPHPLOT Given a graph plot, orient it in such a way that the first
%and second categories are aligned in the middle.

% Copyright 2023 Acadèmia de su Sardu APS

[angle, ~] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory);
graphPlot = rotateGraphPlot(graphPlot, angle);
[~, centerCoords] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory);
graphPlot = centerGraphPlot(graphPlot, centerCoords);
end


function tf = iIsCategory(allData, category)
tf = cellfun(@(e) any([e.Category]==category), allData.Attributes);
end


function tf = iIsCategoryReferenceOfCategory(allData, category)
tf = cellfun(@(e) any([e.Category]==category & [e.IsCategoryReference]), allData.Attributes);
end


function width = iComputeWidth(lims)
width = diff(lims);
end


function [angle, centerCoords] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory)
plotData = table(graphPlot.XData', graphPlot.YData', graphPlot.NodeLabel', ...
    VariableNames={'X', 'Y', 'Name'});
allData = join(plotData, nodeTable, Keys={'Name'});

plotAxes = graphPlot.Parent;
xWidth = iComputeWidth(xlim(plotAxes));

allData.IsFirstCategory = iIsCategory(allData, firstCategory);
allData.IsSecondCategory = iIsCategory(allData, secondCategory);

firstCategoryReferenceIndex = find(iIsCategoryReferenceOfCategory(allData, firstCategory));
secondCategoryReferenceIndex = find(iIsCategoryReferenceOfCategory(allData, secondCategory));

if numel(firstCategoryReferenceIndex)==1
    firstCategoryReferenceCoords = [allData.X(firstCategoryReferenceIndex), allData.Y(firstCategoryReferenceIndex)];
end
if numel(secondCategoryReferenceIndex)==1
    secondCategoryReferenceCoords = [allData.X(secondCategoryReferenceIndex), allData.Y(secondCategoryReferenceIndex)];
end

if numel(firstCategoryReferenceIndex)==1 && numel(secondCategoryReferenceIndex)==0
    centerCoords = firstCategoryReferenceCoords;
    centerCoords(1) = centerCoords(1)+xWidth/4;
    angle = 0;
elseif numel(firstCategoryReferenceIndex)==0 && numel(secondCategoryReferenceIndex)==1
    centerCoords = secondCategoryReferenceCoords;
    centerCoords(1) = centerCoords(1)-xWidth/4;
    angle = 0;
elseif numel(firstCategoryReferenceIndex)==1 && numel(secondCategoryReferenceIndex)==1
    betweenCategoryReferenceCoords = secondCategoryReferenceCoords-firstCategoryReferenceCoords;
    centerCoords = firstCategoryReferenceCoords+betweenCategoryReferenceCoords./2;
    [theta, ~] = cart2pol(betweenCategoryReferenceCoords(1), betweenCategoryReferenceCoords(2));
    angle = -theta;
else
    error("Invalid specification of references in the plot");
end
end