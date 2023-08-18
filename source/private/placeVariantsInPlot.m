function aPlot = placeVariantsInPlot(aPlot, aGraph)
%PLACEVARIANTSINPLOT Place the variants in the plot consistently, according
%to multidimensional scaling.

% Copyright 2023 Acadèmia de su Sardu APS

numNodes = aGraph.numnodes();
numEdges = aGraph.numedges();
endNodes = aGraph.Edges.EndNodes;
weights = aGraph.Edges.Weight;

distances = zeros(numNodes);
for k = 1:numEdges
    distances(endNodes(k, 1), endNodes(k, 2)) = weights(k);
end
if istriu(distances)
    distances = distances + distances';
end

scaledData = cmdscale(distances, 2);
iPrintError(distances, scaledData);

aPlot.XData = scaledData(:, 1);
aPlot.YData = scaledData(:, 2);
end


function iPrintError(distances, scaledData)
selectLower = logical(tril(ones(size(distances)),-1));
Dtriu = distances(selectLower)';

maxRelativeErr = max(abs(Dtriu-pdist(scaledData))) ./ max(Dtriu);
disp("The max relative error due to selecting the first 2 components of multi-dimensional scaling is: " + string(maxRelativeErr * 100) + "%.");
end