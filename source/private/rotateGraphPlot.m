function aPlot = rotateGraphPlot(aPlot, angle)
%ROTATEGRAPHPLOT Given a plot, rotate it of the given angle.

% Copyright 2023 Acadèmia de su Sardu APS
xData = aPlot.XData;
yData = aPlot.YData;

xCenter = mean(xData);
yCenter = mean(yData);

xCentered = xData-xCenter;
yCentered = yData-yCenter;

[theta, rho] = cart2pol(xCentered, yCentered);
newTheta = theta+angle;

[newXCentered, newYCentered] = pol2cart(newTheta, rho);
aPlot.XData = newXCentered+xCenter;
aPlot.YData = newYCentered+yCenter;
end