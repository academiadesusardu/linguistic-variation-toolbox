function [stats, varietySubGraph] = computeVarietyStatistics(inputGraph, variety)
%COMPUTEVARIETYSTATISTICS Compute some statistics on the data given the
%variety.

% Copyright 2023 Acadèmia de su Sardu APS
isVariety = cellfun(@(a) iIsCurrentVariety(a, variety), inputGraph.Nodes.Attributes);
nodeIndices = find(isVariety);
varietySubGraph = subgraph(inputGraph, nodeIndices);

edgesThreshold = computeEdgesWeightThreshold(inputGraph.Edges.Weight);
isEdgeToRemove = varietySubGraph.Edges.Weight>=edgesThreshold;
varietySubGraph = rmedge(varietySubGraph, find(isEdgeToRemove));

stats = varietySubGraph.Nodes;
weights = varietySubGraph.Edges.Weight;
inverseWeights = max(weights) - weights + 1;

stats.Closeness = centrality(varietySubGraph, 'closeness', Cost=weights);
stats.WeightedDegree = centrality(varietySubGraph, 'degree', Importance=inverseWeights);
stats.Betweenness = centrality(varietySubGraph, 'betweenness', Cost=weights);
stats.EigenvectorCentrality = centrality(varietySubGraph, 'eigenvector', Importance=inverseWeights);
end

function tf = iIsCurrentVariety(attributes, variety)
tf = false;
if any([attributes.Variety]==variety)
    tf = true;
end
end