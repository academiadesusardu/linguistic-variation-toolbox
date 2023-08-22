function [stats, categorySubGraph] = computeCategoryStatistics(inputGraph, category)
%COMPUTECATEGORYSTATISTICS Compute some statistics on the data given the
%category.

% Copyright 2023 Acadèmia de su Sardu APS

if ~isempty(category)
    isCategory = cellfun(@(a) iIsCurrentCategory(a, category), inputGraph.Nodes.Attributes);
    nodeIndices = find(isCategory);
    categorySubGraph = subgraph(inputGraph, nodeIndices);
else
    categorySubGraph = inputGraph;
end

stats = struct();
if categorySubGraph.numnodes()==0
    return
end

[stats.Diameter, stats.MeanDistance] = iComputeGeneralStats(categorySubGraph);
stats.VariantData = iComputeVariantStats(categorySubGraph);
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
variantStats.Closeness = centrality(categorySubGraph, 'closeness', Cost=inverseWeights);
variantStats = sortrows(variantStats, "WeightedDegree", "ascend");
end


function [diameter, meanDistance] = iComputeGeneralStats(categorySubGraph)
distances = categorySubGraph.Edges.Weight;
diameter = max(distances, [], "all");
meanDistance = mean(distances, "all");
end