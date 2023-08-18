function currAxis = plotBoxScatter(data, group, xTickLabels)
%PLOTBOXSCATTER Create boxplots with an internal scatterplot

% Copyright 2023 Acadèmia de su Sardu APS

numGroups = numel(unique(group));

% New figure
figure();
currAxis = gca();
boxWidth = 0.5;

% Scatterplots
for groupIndex = 1:numGroups
    position = groupIndex;
    currentData = data(group == groupIndex);

    currentDataSize = size(currentData);
    xRandom = rand(RandStream("twister", "Seed", 0), currentDataSize)-boxWidth;
    xPosition = ones(currentDataSize).*(position + xRandom/4);

    % Scatterplot settings
    scatterPlotHandle = scatter(xPosition, currentData);
    scatterPlotHandle.MarkerEdgeColor = 'none';
    scatterPlotHandle.MarkerFaceAlpha = 0.1;
    scatterPlotHandle.MarkerFaceColor = "red";
    scatterPlotHandle.Marker = 'o';
    hold on;
end

% Boxplot
boxplot(data, group, ...
    position=1:numGroups, ...
    Notch='off', ...
    Widths=boxWidth, ...
    Symbol='');

% Apply boxplot settings
linesInBoxplot = currAxis.Children.Children;
for lineIndex = (numGroups+1):numel(linesInBoxplot)
    linesInBoxplot(lineIndex).Color = "black";
    linesInBoxplot(lineIndex).LineStyle = '-';
end

currAxis.XTickLabel = xTickLabels;
hold off;
end
