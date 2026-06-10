function th = computeEdgesWeightThreshold(weights)
%COMPUTEEDGESWEIGHTTHRESHOLD Given the weights of the edges, compute the
%threshold to be used for statistics.

% Copyright 2023 Acadèmia de su Sardu APS

th = median(weights);
end