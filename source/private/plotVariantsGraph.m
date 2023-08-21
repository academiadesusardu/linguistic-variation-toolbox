function [plotObject, plotGraph] = plotVariantsGraph(inputGraph, options)
%PLOTVARIANTSGRAPH Given a graph, plot it according to the expected layout for a
%set of variants.

% Copyright 2023 Acadèmia de su Sardu APS

currFigure = gcf();
currAxes = axes(currFigure, Visible="off", Color="none");

plotGraph = inputGraph;

[plotGraph.Nodes.Marker, ...
    plotGraph.Nodes.Color, ...
    plotGraph.Nodes.MarkerSize] = iGetNodesSpec(plotGraph.Nodes);
plotGraph.Nodes.Color = iGetRgbColor(plotGraph.Nodes.Color);
[plotGraph.Edges.Color, ...
    plotGraph.Edges.Width] = iGetEdgesSpec(plotGraph.Edges.Weight);

if options.PlacementAlgorithm == getForcePlacementAlgorithmString()
    iterations = 5e3;
else
    iterations = 1;
end

plotObject = plot(plotGraph, ...
    Parent=currAxes, ...
    NodeLabel=plotGraph.Nodes.Name, ...
    NodeColor=plotGraph.Nodes.Color, ...
    NodeFontWeight="bold", ...
    Marker=plotGraph.Nodes.Marker, ...
    MarkerSize=plotGraph.Nodes.MarkerSize, ...
    EdgeColor=plotGraph.Edges.Color, ...
    LineWidth=plotGraph.Edges.Width, ...
    Layout="force", ...
    WeightEffect='direct', ...
    Iterations=iterations);

if options.PlacementAlgorithm == getMdsPlacementAlgorithmString()
    plotObject = placeVariantsInPlot(plotObject, plotGraph);
end

if isfield(options, 'CenterCategories')
    plotObject = orientGraphPlot(plotObject, ...
        plotGraph.Nodes, ...
        options.CenterCategories(1), ...
        options.CenterCategories(2));
end

colorBar = colorbar(currAxes, "eastoutside");
colorMap = iColorMap(plotGraph.Edges.Weight);
colormap(currAxes, colorMap);
colorBar = iSetColorBarTicks(colorBar, size(colorMap, 1));
colorBar.Label.String = "Edge colour: distance between variants";

edgeTable = plotGraph.Edges;
if options.Mode == getProximalPlotModeString()
    lineStyle = cell(height(edgeTable), 1);
    lineStyle(edgeTable.IsProximal) = repmat({'-'}, [sum(edgeTable.IsProximal), 1]);
    lineStyle(~edgeTable.IsProximal) = repmat({'none'}, [sum(~edgeTable.IsProximal), 1]);
    plotObject.LineStyle = lineStyle;
end
end


function [edgesColor, edgesWidth] = iGetEdgesSpec(weights)
colorMap = iColorMap(weights);
[colors, widths] = arrayfun(@(w) iEdgeComputeColorAndWidth(w, colorMap), ...
    weights, UniformOutput=false);
edgesColor = cell2mat(colors);
edgesWidth = cell2mat(widths);
end


function colorSpec = iGetRgbColor(colorHex)
% Given the color's hex codes, get the spec in a way that can be used in
% MATLAB plots
colorSpec = cell2mat(cellfun(@hex2rgb, ...
    cellstr(colorHex), ...
    UniformOutput=false));
end


function colorBar = iSetColorBarTicks(colorBar, numColors)
ticks = linspace(0, 1, 2*numColors + 1);
colorBar.Ticks = ticks;
colorBar.TickLength = 0;

labels = string(1:numColors);
labels(end) = "≥" + labels(end);
% Interleaving
rowsToInterleave = [labels; repmat("", size(labels))];
tickLabels = [rowsToInterleave(:)]';
colorBar.TickLabels = cellstr(["", tickLabels]);
end


function [nodeMarkers, nodeColors, nodeMarkerSize] = iGetNodesSpec(nodeTable)
% Define the basic style for the nodes in the graph
tableHeight = height(nodeTable);
nodeMarkers = repmat("", [tableHeight, 1]);
nodeMarkerSize = repmat(4, [tableHeight, 1]);
nodeColors = repmat("black", [tableHeight, 1]);

numCategories = numel(allCategories());
markers =   [ ...
    "o", ...
    "square", ...
    "*", ...
    "diamond", ...
    "x", ...
    "+", ....
    "hexagram"];
colors =    [ ...
    "#4daf4a", ...
    "#e41a1c", ...
    "#377eb8", ...
    "#984ea3", ...
    "#ff7f00", ...
    "#ffff33", ...
    "#a65628" ];

for k = 1:tableHeight
    currAttributes = nodeTable.Attributes{k};

    if length(currAttributes)>1
        styleIndex = numCategories+1;
    else
        currCategory = currAttributes.Category;
        styleIndex = iGetCategoryIndex(currCategory);
    end

    if nodeTable.IsCategoryReference(k)
        nodeMarkers(k) = "pentagram";
        nodeMarkerSize(k) = 6;
    else
        nodeMarkers(k) = markers(styleIndex);
    end
    nodeColors(k) = colors(styleIndex);
end
end


function index = iGetCategoryIndex(category)
% Get the index of the category among all the categories
index = find(allCategories() == category);
end

function cm = iColorMap(data)
numColors = computeEdgesWeightThreshold(data);
cm = gray(numColors);
end


function [color, width] = iEdgeComputeColorAndWidth(weight, colorMap)
% Given the edge's weight, determine what it should look like
maxColors = size(colorMap, 1);
index = weight;
if index>=maxColors
    index = maxColors;
end
color = colorMap(index, :);

width = 0.25;
if weight<=1
    width = 1;
end
end