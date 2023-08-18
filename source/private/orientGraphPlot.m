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


function tf = iIsStandardOfCategory(allData, category)
tf = cellfun(@(e) any([e.Category]==category & [e.IsStandard]), allData.Attributes);
end


function width = iComputeWidth(lims)
width = diff(lims);
end


function [angle, centerCoords] = iFindCenter(graphPlot, nodeTable, firstCategory, secondCategory)
plotData = table(graphPlot.XData', graphPlot.YData', graphPlot.NodeLabel', ...
    VariableNames={'X', 'Y', 'Variant'});
allData = join(plotData, nodeTable, Keys={'Variant'});

plotAxes = graphPlot.Parent;
xWidth = iComputeWidth(xlim(plotAxes));

allData.IsFirstCategory = iIsCategory(allData, firstCategory);
allData.IsSecondCategory = iIsCategory(allData, secondCategory);

firstStandardIndex = find(iIsStandardOfCategory(allData, firstCategory));
secondStandardIndex = find(iIsStandardOfCategory(allData, secondCategory));

if numel(firstStandardIndex)==1
    firstStandardCoords = [allData.X(firstStandardIndex), allData.Y(firstStandardIndex)];
end
if numel(secondStandardIndex)==1
    secondStandardCoords = [allData.X(secondStandardIndex), allData.Y(secondStandardIndex)];
end

if numel(firstStandardIndex)==1 && numel(secondStandardIndex)==0
    centerCoords = firstStandardCoords;
    centerCoords(1) = centerCoords(1)+xWidth/4;
    angle = 0;
elseif numel(firstStandardIndex)==0 && numel(secondStandardIndex)==1
    centerCoords = secondStandardCoords;
    centerCoords(1) = centerCoords(1)-xWidth/4;
    angle = 0;
elseif numel(firstStandardIndex)==1 && numel(secondStandardIndex)==1
    betweenStandardCoords = secondStandardCoords-firstStandardCoords;
    centerCoords = firstStandardCoords+betweenStandardCoords./2;
    [theta, ~] = cart2pol(betweenStandardCoords(1), betweenStandardCoords(2));
    angle = -theta;
else
    error("Invalid specification of standards to reference in the plot");
end
end