function [stats, categorySubGraph] = computeCategoryStatistics(inputGraph, category)
%COMPUTECATEGORYSTATISTICS Compute some statistics on the data given the
%category.

% Copyright 2023 Acadèmia de su Sardu APS

if ~isempty(category)
    isCategory = cellfun(@(a) iIsCurrentCategory(a, category), ...
        inputGraph.Nodes.Attributes);
    nodeIndices = find(isCategory);
    categorySubGraph = subgraph(inputGraph, nodeIndices);
    categorySubGraph.Nodes.IsCategoryReference = ...
        isCategoryReferenceIn(categorySubGraph, category);
else
    categorySubGraph = inputGraph;
end

if categorySubGraph.numnodes()==0
    stats = struct();
    return
end

variantData = iComputeVariantStats(categorySubGraph);

stats = iComputeGeneralStats(categorySubGraph, variantData.DistanceFromBaricentre);
stats.VariantData = variantData;
end


function tf = iIsCurrentCategory(attributes, category)
tf = false;
if any([attributes.Category]==category)
    tf = true;
end
end


function variantStats = iComputeVariantStats(categorySubGraph)
variantStats = categorySubGraph.Nodes;
weights = categorySubGraph.Edges.Weight;
numVariants = categorySubGraph.numnodes();
inverseWeights = max(weights) - weights + 1;

variantStats.WeightedDegree = centrality(categorySubGraph, 'degree', Importance=weights);
variantStats.MeanDistance = variantStats.WeightedDegree./(numVariants-1);
variantStats.RangeDistance = iComputeWeightRange(categorySubGraph);
variantStats.Closeness = centrality(categorySubGraph, 'closeness', Cost=inverseWeights);
variantStats.DistanceFromBaricentre = iComputeDistanceFromBaricentre(categorySubGraph);
variantStats = sortrows(variantStats, "WeightedDegree", "ascend");
end


function generalStats = iComputeGeneralStats(categorySubGraph, distanceFromBaricentre)
generalStats = struct();
distances = categorySubGraph.Edges.Weight;
if isempty(distances)
    generalStats.Diameter = 0;
    generalStats.MeanDistance = nan;
    generalStats.RangeDistance = nan;
    generalStats.MeanDistanceFromBaricentre = 0;
else
    generalStats.Diameter = max(distances, [], "all");
    generalStats.MeanDistance = mean(distances, "all");
    generalStats.RangeDistance = range(distances, "all");
    generalStats.MeanDistanceFromBaricentre = mean(distanceFromBaricentre, "all");
end
generalStats.NumVariants = numnodes(categorySubGraph);
end


function outRange = iComputeWeightRange(aGraph)
numNodes = aGraph.numnodes();
if numNodes<=1
    outRange = nan(numNodes, 1);
    return
end

weights = aGraph.Edges.Weight;
outRange = zeros([numNodes, 1]);
[startNodes, endNodes] = aGraph.findedge();
for k = 1:numNodes
    currEdges = startNodes==k | endNodes==k;
    outRange(k) = range(weights(currEdges));
end
end

function outDistance = iComputeDistanceFromBaricentre(aGraph)
distanceMatrix = aGraph.adjacency('weighted');
numNodes = size(distanceMatrix, 1);
if numNodes<=1
    outDistance = 0;
    return
end

coordinates = cmdscale(full(distanceMatrix));
baricentre = mean(coordinates);
centeredCoordinates = coordinates-baricentre;
outDistance = vecnorm(centeredCoordinates, 2, 2);
end