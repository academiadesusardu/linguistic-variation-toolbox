function aPlot = placeVariantsInPlot(aPlot, aGraph)
%PLACEVARIANTSINPLOT Place the variants in the plot consistently, according
%to multidimensional scaling.

% Copyright 2023 Acadèmia de su Sardu APS

numNodes = aGraph.numnodes();
if numNodes==1
    return
end

numEdges = aGraph.numedges();
endNodes = aGraph.Edges.EndNodes;
weights = aGraph.Edges.Weight;

distances = zeros(numNodes);
for k = 1:numEdges
    fromIndex = aGraph.findnode(endNodes(k, 1));
    toIndex = aGraph.findnode(endNodes(k, 2));
    distances(fromIndex, toIndex) = weights(k);
end
if istriu(distances)
    distances = distances + distances';
end

scaledData = cmdscale(distances, 2);

if size(scaledData, 2)==2
    iPrintError(distances, scaledData);
    aPlot.XData = scaledData(:, 1);
    aPlot.YData = scaledData(:, 2);
else
    disp("Falling back to the 'force' layout algorithm.")
end
end

function iPrintError(distances, scaledData)
selectLower = logical(tril(ones(size(distances)),-1));
Dtriu = distances(selectLower)';

maxRelativeErr = max(abs(Dtriu-pdist(scaledData))) ./ max(Dtriu);
disp("The max relative error due to selecting the first 2 components of multi-dimensional scaling is: " + string(maxRelativeErr * 100) + "%.");
end