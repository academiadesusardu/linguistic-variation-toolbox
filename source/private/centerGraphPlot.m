function aPlot = centerGraphPlot(aPlot, centerCoordinates)
%CENTERGRAPHPLOT Given a plot, center it to the given point.

% Copyright 2023 Acadèmia de su Sardu APS
xData = aPlot.XData;
yData = aPlot.YData;

xOldCenter = mean(xData);
yOldCenter = mean(yData);

xCenterDiff = centerCoordinates(1)-xOldCenter;
yCenterDiff = centerCoordinates(2)-yOldCenter;

aPlot.XData = xData+xCenterDiff;
aPlot.YData = yData+yCenterDiff;
end