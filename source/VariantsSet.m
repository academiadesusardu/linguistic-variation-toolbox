classdef VariantsSet
    %VARIANTSSET A set of variants of the same word.
    %
    % Syntax:
    %   G = VariantsSet(VN, VR)
    %       Construct the object given:
    %           - The array of variants VN
    %           - The corresponding varieties VR
    %       To determine the statistics, use a simple Levenshtein distance.
    %
    %   G = VariantsSet(VN, VR, S)
    %       Construct the object given VN, VR, and:
    %           - a logical array S stating whether the variant
    %             is standard or not.
    %       To determine the statistics, use a simple Levenshtein distance.
    %
    %   G = VariantsSet(VN, VA)
    %       Construct the object given VN and:
    %           - a cell array of variant attributes VA specifying the
    %             attributes of every variant in VN.
    %       To determine the statistics, use a simple Levenshtein distance.
    %
    %   G = VariantsSet(__, DistanceFunction=F)
    %       Construct the object with the syntax(es) in the previous examples,
    %       but also specify a custom distance function.
    %
    %  Example:
    %   allVarieties(["camp", "log"]);
    %   variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"];
    %   varieties = {"camp", "log", "log"};
    %   isStandard = [true, false, true];
    %   set = VariantsSet(variants, varieties, isStandard);
    %   plot(set);

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(SetAccess=immutable)
        % All the data that was provided about the variants
        DataTable

        % The distance function that was used to compute the statistics
        DistanceFunction
    end

    properties(Access=private)
        % Internal graph object used for statistics and plotting
        InternalGraph
    end

    methods
        function obj = VariantsSet(variants, varietiesOrAttributes, isStandard, options)
            %VARIANTSSET Construct an object representing a set of
            % variants of the same word.

            arguments
                variants {mustBeText}
                varietiesOrAttributes cell
                isStandard logical = false(length(variants), 1)
                options.DistanceFunction (1,1) function_handle = @simpleLevenshtein
            end
            variants = reshape(string(variants), [], 1);
            [attributes, isStandard] = ...
                iComputeAttributes(varietiesOrAttributes, isStandard);

            dataTable = table(variants, attributes, isStandard);
            dataTable.Properties.VariableNames = {'Variant', 'Attributes', 'IsStandard'};

            obj.DataTable = dataTable;
            obj.DistanceFunction = options.DistanceFunction;

            nodesTable = iCreateNodesTable(dataTable);
            edgesTable = iCreateEdgesTable(dataTable, obj.DistanceFunction);
            obj.InternalGraph = graph(edgesTable, nodesTable);
        end

        function graphObject = toGraph(obj)
            %TOGRAPH Convert to a graph object.
            graphObject = obj.InternalGraph;
        end

        function [plotObject, plotGraph] = plot(obj, options)
            %PLOT Plot the object
            arguments
                obj (1,1)
                options.CenterVarieties (1, 2) string
            end

            [plotObject, plotGraph] = plotVariantsGraph(obj.InternalGraph, options);
        end

        function stats = computeStatistics(obj)
            %COMPUTESTATISTICS Compute the statistics over the input data.
            varieties = allVarieties();
            numVarieties = length(varieties);
            stats = struct();

            for k = 1:numVarieties
                currVariety = varieties(k);
                stats.(currVariety) = computeVarietyStatistics(obj.InternalGraph, currVariety);
            end
        end
    end
end


function edgesTable = iCreateEdgesTable(dataTable, distanceFunction)
% Create the edges table for the internal graph
numWords = height(dataTable);
numEdges = (numWords^2-numWords)/2;
endNodes = zeros(numEdges, 2);
weights = zeros(numEdges, 1);

k = 1;
for ii = 1:numWords
    for jj = ii+1:numWords
        endNodes(k, :) = [ii, jj];
        weights(k) = distanceFunction( ...
            dataTable.Variant(ii), dataTable.Variant(jj));
        k = k+1;
    end
end

edgesTable = table(endNodes, weights, ...
    VariableNames=["EndNodes", "Weight"]);
end


function nodeTable = iCreateNodesTable(dataTable)
% Create the table of nodes for the plot
nodeTable = dataTable(:, {'Variant', 'Attributes', 'IsStandard'});
end


function [attributes, isActuallyStandard] = iComputeAttributes(varietiesOrAttributes, isStandard)
% Compute all the attributes of the variants
inputLength = length(varietiesOrAttributes);
attributes = cell(inputLength, 1);
isActuallyStandard = false(inputLength, 1);

for k = 1:inputLength
    currElement = varietiesOrAttributes{k};
    currElementAttributes = [];

    for j = 1:length(currElement)
        currAttribute = currElement(j);
        if isstring(currAttribute)
            assert(ismember(currAttribute, allVarieties()), ...
                "The variety should be one of those specified by 'allVarieties'.")

            currElementIsStandard = isStandard(k);
            attributeToAdd = VariantAttribute(...
                currAttribute, ...
                currElementIsStandard);
        elseif isa(varietiesOrAttributes, 'VariantAttribute')
            attributeToAdd = currAttribute;
        else
            error("Invalid specification of the attributes of variant number %d: the input should be a cell array, where each cell contains either an array of strings or an array of VariantAttribute objects.", k);
        end
        currElementAttributes = [currElementAttributes; attributeToAdd]; %#ok<AGROW>
    end
    currElementIsActuallyStandard = any([currElementAttributes.IsStandard]);

    attributes{k} = currElementAttributes;
    isActuallyStandard(k) = currElementIsActuallyStandard;
end
end