function aPlot = centerGraphPlot(aPlot, centerCoordinates)
%CENTERGRAPHPLOT Given a plot, center it to the given point.

% Copyright 2023 Acadèmia de su Sardu APS

xData = aPlot.XData;
yData = aPlot.YData;

maxXDiff = iMaxDistance(xData, centerCoordinates(1));
maxYDiff = iMaxDistance(yData, centerCoordinates(2));

plotAxis = aPlot.Parent;
finalYWidth = maxYDiff*1.4;
finalXWidth = maxXDiff*1.4;

if finalYWidth>0
    ylim(plotAxis, [centerCoordinates(2)-finalYWidth, centerCoordinates(2)+finalYWidth]);
end
if finalXWidth>0
    xlim(plotAxis, [centerCoordinates(1)-finalXWidth, centerCoordinates(1)+finalXWidth]);
end
end


function dist = iMaxDistance(data, center)
dist = max(abs(data-center));
end