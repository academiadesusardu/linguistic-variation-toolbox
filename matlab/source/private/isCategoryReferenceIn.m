function tf = isCategoryReferenceIn(aGraph, category)
%ISCATEGORYREFERENCE    Given a graph where each node represents a variant,
%get an array that says whether each node is the category reference for the
%given category.

% Copyright 2023 Acadèmia de su Sardu APS
graphNodes = aGraph.Nodes;
numNodes = aGraph.numnodes();
tf = false(aGraph.numnodes(), 1);

for k = 1:numNodes
    currAttributes = graphNodes.Attributes{k};

    for j = 1:numel(currAttributes)
        if currAttributes(j).Category==category && currAttributes(j).IsCategoryReference
            tf(k) = true;
        end
    end
end
end

