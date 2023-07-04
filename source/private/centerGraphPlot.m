function aPlot = centerGraphPlot(aPlot, centerCoordinates)
%CENTERGRAPHPLOT Given a plot, center it to the given point.

% Copyright 2023 Acadèmia de su Sardu APS
xData = aPlot.XData;
yData = aPlot.YData;

maxXDiff = iMaxDistance(xData, centerCoordinates(1));
maxYDiff = iMaxDistance(yData, centerCoordinates(2));

% if maxXDiff>halfXWidth
%     maxXWidth = maxXDiff+padding;
% else
%     maxXWidth = halfXWidth;
% end
% if maxYDiff>halfYWidth
%     maxYWidth = maxYDiff+padding;
% else
%     maxYWidth = halfYWidth;
% end
% 
% impliedYWidth = maxXWidth/ratio;
% impliedXWidth = maxYWidth*ratio;
% 
plotAxis = aPlot.Parent;
% if impliedYWidth>maxYWidth
%     finalYWidth = impliedYWidth;
%     finalXWidth = maxXWidth;
% elseif impliedXWidth>maxXWidth
%     finalYWidth = maxYWidth;
%     finalXWidth = impliedXWidth;
% else
%    finalYWidth = maxYWidth;
%    finalXWidth = maxXWidth;
% end
finalYWidth = maxYDiff*1.4;
finalXWidth = maxXDiff*1.4;
disp(centerCoordinates);
ylim(plotAxis, [centerCoordinates(2)-finalYWidth, centerCoordinates(2)+finalYWidth]);
xlim(plotAxis, [centerCoordinates(1)-finalXWidth, centerCoordinates(1)+finalXWidth]);
end

function dist = iMaxDistance(data, center)
dist = max(abs(data-center));
end