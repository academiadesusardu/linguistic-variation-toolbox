function [stats, categorySubGraph] = computeCategoryStatistics(inputGraph, category)
%COMPUTECATEGORYSTATISTICS Compute some statistics on the data given the
%category.

% Copyright 2023 Acadèmia de su Sardu APS

isCategory = cellfun(@(a) iIsCurrentCategory(a, category), inputGraph.Nodes.Attributes);
nodeIndices = find(isCategory);
categorySubGraph = subgraph(inputGraph, nodeIndices);

edgesThreshold = computeEdgesWeightThreshold(inputGraph.Edges.Weight);
isEdgeToRemove = categorySubGraph.Edges.Weight>=edgesThreshold;
categorySubGraph = rmedge(categorySubGraph, find(isEdgeToRemove));

stats = categorySubGraph.Nodes;
weights = categorySubGraph.Edges.Weight;
inverseWeights = max(weights) - weights + 1;

stats.Closeness = centrality(categorySubGraph, 'closeness', Cost=weights);
stats.WeightedDegree = centrality(categorySubGraph, 'degree', Importance=inverseWeights);
stats.Betweenness = centrality(categorySubGraph, 'betweenness', Cost=weights);
stats.EigenvectorCentrality = centrality(categorySubGraph, 'eigenvector', Importance=inverseWeights);
end

function tf = iIsCurrentCategory(attributes, category)
tf = false;
if any([attributes.Category]==category)
    tf = true;
end
end