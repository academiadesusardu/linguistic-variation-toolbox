function [stats, categorySubGraph] = computeCategoryStatistics(inputGraph, category)
%COMPUTECATEGORYSTATISTICS Compute some statistics on the data given the
%category.

% Copyright 2023 Acadèmia de su Sardu APS

isCategory = cellfun(@(a) iIsCurrentCategory(a, category), inputGraph.Nodes.Attributes);
nodeIndices = find(isCategory);
categorySubGraph = subgraph(inputGraph, nodeIndices);

stats = categorySubGraph.Nodes;
weights = categorySubGraph.Edges.Weight;
inverseWeights = max(weights) - weights + 1;

stats.WeightedDegree = centrality(categorySubGraph, 'degree', Importance=weights);
stats.Closeness = centrality(categorySubGraph, 'closeness', Cost=inverseWeights);

stats = sortrows(stats, "Closeness", "ascend");
end

function tf = iIsCurrentCategory(attributes, category)
tf = false;
if any([attributes.Category]==category)
    tf = true;
end
end