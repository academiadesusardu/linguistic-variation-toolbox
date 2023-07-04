function graphPlot = orientGraphPlot(graphPlot, nodeTable, firstVariety, secondVariety)
%ORIENTGRAPHPLOT Given a graph plot, orient it in such a way that the first
%and second varieties are aligned in the middle.

% Copyright 2023 Acadèmia de su Sardu APS
plotData = table(graphPlot.XData', graphPlot.YData', graphPlot.NodeLabel', ...
    VariableNames={'X', 'Y', 'Variant'});
allData = join(plotData, nodeTable, Keys={'Variant'});

plotAxes = graphPlot.Parent;
xWidth = iComputeWidth(xlim(plotAxes));

allData.IsFirstVariety = iIsVariety(allData, firstVariety);
allData.IsSecondVariety = iIsVariety(allData, secondVariety);

firstStandardIndex = find(iIsStandardOfVariety(allData, firstVariety));
secondStandardIndex = find(iIsStandardOfVariety(allData, secondVariety));

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

graphPlot = centerGraphPlot(graphPlot, centerCoords);
graphPlot = rotateGraphPlot(graphPlot, angle);
end


function tf = iIsVariety(allData, variety)
tf = cellfun(@(e)e.Variety==variety, allData.Attributes);
end


function tf = iIsStandardOfVariety(allData, variety)
tf = cellfun(@(e)e.Variety==variety & e.IsStandard, allData.Attributes);
end


function width = iComputeWidth(lims)
width = diff(lims);
end