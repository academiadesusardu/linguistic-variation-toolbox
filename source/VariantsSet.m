classdef VariantsSet < handle
    %VARIANTSSET A set of variants of the same word.
    %
    % Syntax:
    %   G = VariantsSet(VN, VR)
    %       Construct the object given:
    %           - The array of variants VN
    %           - The corresponding categories VR
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
    %   allCategories(["camp", "log"]);
    %   variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"];
    %   categories = {"camp", "log", "log"};
    %   isStandard = [true, false, true];
    %   set = VariantsSet(variants, categories, isStandard);
    %   plot(set);

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(SetAccess=immutable)
        % All the data that was provided about the variants
        VariantTable

        % All the data that was computed about the distances
        DistanceTable

        % The distance function that was used to compute the statistics
        DistanceFunction
    end

    properties(Access=private)
        % Internal graph object used for statistics and plotting
        InternalGraph

        % Internal digraph object used for statistics and plotting
        InternalDigraph

        % The table of distances between variants. Each distance appears
        % only once.
        UniqueDistances
    end

    methods
        function obj = VariantsSet(variants, categoriesOrAttributes, isStandard, options)
            %VARIANTSSET Construct an object representing a set of
            % variants of the same word.

            arguments
                variants {mustBeText}
                categoriesOrAttributes cell
                isStandard logical = false(length(variants), 1)
                options.DistanceFunction (1,1) function_handle = @simpleLevenshtein
            end
            variants = reshape(string(variants), [], 1);
            assert(numel(unique(variants))==numel(variants), ...
                "The elements in the variant array are not unique.")


            [attributes, isStandard] = ...
                iComputeAttributes(categoriesOrAttributes, isStandard);

            dataTable = table(variants, attributes, isStandard);
            dataTable.Properties.VariableNames = {'Variant', 'Attributes', 'IsStandard'};

            obj.VariantTable = dataTable;
            obj.DistanceFunction = options.DistanceFunction;

            nodesTable = iCreateNodesTable(dataTable);
            edgesTable = iCreateEdgesTable(dataTable, obj.DistanceFunction);
            obj.InternalGraph = graph(edgesTable, nodesTable);

            obj.InternalDigraph = iGraphToDigraph(obj.InternalGraph);
            obj.InternalDigraph.Edges.IsProximal = iFindProximalNodes(obj.InternalDigraph.Edges);

            obj.DistanceTable = iCreateDistanceTable(obj.InternalDigraph);
        end


        function numVariants = getNumberOfVariants(obj)
            %GETNUMBEROFVARIANTS Get the total number of variants

            numVariants = height(obj.VariantTable);
        end


        function categories = getCategoriesOf(obj, variant)
            %GETVARIETIESOF Get the categories of a given variant.

            arguments
                obj (1,1)
                variant (1, 1) string
            end
            variantSelector = obj.selectVariant(variant);
            categories = [obj.VariantTable.Attributes{variantSelector}.Category];
        end


        function variants = getVariantsIn(obj, category)
            %GETVARIANTSIN Get the variants that belong to the given
            %category.

            arguments
                obj (1,1)
                category (1, 1) string
            end
            validateCategory(category);

            categoriesPerVariant = arrayfun(@(v) obj.getCategoriesOf(v), ...
                obj.VariantTable.Variant, ...
                UniformOutput=false);
            isOfThisCategory = cellfun(@(categories) ismember(category, categories), ...
                categoriesPerVariant, ...
                UniformOutput=true);
            variants = obj.VariantTable.Variant(isOfThisCategory);
        end


        function tf = isStandard(obj, variant)
            %ISSTANDARD Return true if the given variant the standard of
            %one or more categories.

            arguments
                obj (1,1)
                variant (1, 1) string
            end
            variantSelector = obj.selectVariant(variant);
            tf = any([obj.VariantTable.Attributes{variantSelector}.IsStandard]);
        end


        function variants = getStandardIn(obj, category)
            %GETSTANDARDIN Get the standard variant in the given category.

            arguments
                obj (1,1)
                category (1, 1) string
            end
            validateCategory(category);

            variants = repmat("", [obj.getNumberOfVariants(), 1]);
            numFoundVariants = 0;

            for k = 1:obj.getNumberOfVariants()
                currVariant = obj.VariantTable.Variant(k);
                currAttributes = obj.VariantTable.Attributes{k};

                for j = 1:numel(currAttributes)
                    if currAttributes(j).Category==category && currAttributes(j).IsStandard
                        variants(numFoundVariants+1) = currVariant;
                        numFoundVariants = numFoundVariants+1;
                    end
                end
            end

            if numFoundVariants == 0
                variants = [];
            elseif numFoundVariants < length(variants)
                variants(numFoundVariants+1:end) = [];
            end
        end


        function [plotObject, plotGraph] = plot(obj, options)
            %PLOT Represent the set of variants graphically.
            %
            % Syntax:
            %   [PO, G] = plot(VS)
            %       Plot the object with default settings. Returns a handle
            %       to the plot and the underlying graph object (graph or
            %       digraph) that was used for the plot.
            %
            %   [PO, G] = plot(VS, Mode=M)
            %       Plot different kinds of chart: "complete" or
            %       "proximal". By default, it's "complete".
            %
            %   [PO, G] = plot(__, CenterCategories=VC)
            %       Plot the chart but center the plot around the two
            %       categories specified in VC.
            %
            %   [PO, G] = plot(VS, PlacementAlgorithm=M)
            %       Specify the placement algorithm: "force", i.e. 
            %       force-directed graph plot, or "mds", i.e. 
            %       multi-dimensional scaling. By default, it's "force".

            arguments
                obj (1,1)
                options.CenterCategories (1, 2) string
                options.Mode (1, 1) = getCompletePlotModeString()
                options.PlacementAlgorithm (1, 1) = getForcePlacementAlgorithmString()
            end
            options.Mode = iCheckPlotOption(options.Mode, ...
                [getCompletePlotModeString(), getProximalPlotModeString()], ...
                "Allowed plot modes are: ");
            options.PlacementAlgorithm = iCheckPlotOption(options.PlacementAlgorithm, ...
                [getForcePlacementAlgorithmString(), getMdsPlacementAlgorithmString()], ...
                "Allowed placement algorithms are: ");

            if options.Mode == getProximalPlotModeString()
                inputGraph = obj.InternalDigraph;
            else
                inputGraph = obj.InternalGraph;
            end
            [plotObject, plotGraph] = plotVariantsGraph(inputGraph, options);
            title(plotObject.Parent, "Variants");
        end


        function plotAxes = plotDistances(obj, categories)
            %PLOT Create a plot that represents the statistics of distances
            % between variants in one or more categories.
            %
            % Syntax:
            %   PO = plotDistances(VS, C)
            %       Create a plot that represents the distances within
            %       category C. Returns a handle to the axes.

            arguments
                obj (1,1)
            end

            arguments(Repeating)
                categories
            end

            numPlots = numel(categories);
            dataToPlot = cell(numPlots, 1);
            groupOfData = cell(numPlots, 1);
            labelOfData = repmat("", [numPlots, 1]);

            for k = 1:numPlots
                currCategories = unique(categories{k});
                numCurrCategories = numel(currCategories);
                currData = [];

                if numCurrCategories == 0
                    currLabel = "All";
                    wholeUniqueTable = obj.getUniqueDistancesTable();
                    currData = wholeUniqueTable.Distance;
                elseif numCurrCategories == 1
                    currLabel = currCategories;
                    currCategories = [currCategories, currCategories]; %#ok<AGROW>
                    numCurrCategories = 2;
                else
                    currLabel = join(currCategories, ", ");
                end

                for i = 1:(numCurrCategories-1)
                    currFirstVariants = obj.getVariantsIn(currCategories(i));
                    for j = (i+1):numCurrCategories
                        currSecondVariants = obj.getVariantsIn(currCategories(j));
                        currData = [currData; ...
                            obj.findDistancesBetweenVariants(...
                            currFirstVariants, currSecondVariants)]; %#ok<AGROW>
                    end
                end

                dataToPlot{k} = currData;
                groupOfData{k} = repmat(k, size(currData));
                labelOfData(k) = currLabel;
            end

            plotAxes = plotBoxScatter(cell2mat(dataToPlot), ...
                cell2mat(groupOfData), ...
                labelOfData);
            title(plotAxes, "Distance between variants");
        end


        function stats = computeStatistics(obj)
            %COMPUTESTATISTICS Compute the statistics over the input data.

            categories = allCategories();
            numCategories = length(categories);
            stats = struct();

            for k = 1:numCategories
                currCategory = categories(k);
                stats.(currCategory) = computeCategoryStatistics(obj.InternalGraph, currCategory);
            end
        end
    end


    methods(Access=private)
        function variantSelector = selectVariant(obj, variant)
            % Select the input variant in the VariantTable.
            variantSelector = obj.VariantTable.Variant == variant;
            assert(any(variantSelector), ...
                "The input variant was not found in this set.")
        end


        function uniqueDistances = getUniqueDistancesTable(obj)
            % Get all the distances between variants, counting them only
            % once
            if isempty(obj.UniqueDistances)
                rowsOfInterest = obj.DistanceTable(:, ["StartVariant", "EndVariant", "Distance"]);
                rowsOfInterest.EndVariants = [rowsOfInterest.StartVariant, rowsOfInterest.EndVariant];
                rowsOfInterest = removevars(rowsOfInterest, ["StartVariant", "EndVariant"]);

                % Divide EndVariants into cells
                rowsOfInterest.EndVariants = iSortEndVariantCouples(rowsOfInterest.EndVariants);
                obj.UniqueDistances = unique(rowsOfInterest);
            end
            uniqueDistances = obj.UniqueDistances;
        end


        function uniqueDistances = findDistancesBetweenVariants(obj, firstVariants, secondVariants)
            % Given two sets of variants, find the distances between them,
            % but count the distance between two variants only once.
            uniqueDistances = obj.getUniqueDistancesTable();

            selectEdges = @(r) iSelectVariantCouple(r, firstVariants, secondVariants);
            currEdgesSelector = table2array(rowfun(selectEdges, ...
                uniqueDistances, ...
                InputVariables='EndVariants'));
            currEdges = uniqueDistances(currEdgesSelector, :);
            uniqueDistances = currEdges.Distance;
        end
    end
end


function plotOption = iCheckPlotOption(plotOption, allowedValues, baseDiagnostic)
plotOption = string(plotOption);
assert(ismember(plotOption, allowedValues), ...
    baseDiagnostic + join(allowedValues, ", "));
end


function edgesTable = iCreateEdgesTable(dataTable, distanceFunction)
% Create the edges table for the internal graph

numWords = height(dataTable);
numEdges = (numWords^2-numWords)/2;
endNodes = zeros(numEdges, 2);
weights = zeros(numEdges, 1);

k = 1;
for ii = 1:numWords
    for jj = (ii+1):numWords
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


function [attributes, isActuallyStandard] = iComputeAttributes(categoriesOrAttributes, isStandard)
% Compute all the attributes of the variants

inputLength = length(categoriesOrAttributes);
attributes = cell(inputLength, 1);
isActuallyStandard = false(inputLength, 1);

for k = 1:inputLength
    currElement = categoriesOrAttributes{k};
    currElementAttributes = [];

    for j = 1:length(currElement)
        currAttribute = currElement(j);
        if isstring(currAttribute)
            validateCategory(currAttribute);

            currElementIsStandard = isStandard(k);
            attributeToAdd = VariantAttribute(...
                currAttribute, ...
                currElementIsStandard);
        elseif isa(categoriesOrAttributes, 'VariantAttribute')
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


function isProximal = iFindProximalNodes(edgesTable)
% Compute edges that won't show in the final graph

numEdges = height(edgesTable);
numNodes = iNumNodesFromEdges(edgesTable);
isProximal = false(numEdges, 1);
weights = edgesTable.Weight;

for ii = 1:numNodes
    currEdgeSelector = edgesTable.EndNodes(:, 1) == ii;
    if ~any(currEdgeSelector)
        continue;
    end

    minWeight = min(weights(currEdgeSelector));
    weightsOfInterest = weights==minWeight;
    currProximal = currEdgeSelector & weightsOfInterest;
    isProximal(currProximal) = true;
end
end


function num = iNumNodesFromEdges(edgesTable)
% Compute the number of nodes in a graph given the table of edges

num = length(unique([edgesTable.EndNodes(:)]));
end


function aDigraph = iGraphToDigraph(aGraph)
% Convert a graph object to a digraph object.

nodes = aGraph.Nodes;
edges = aGraph.Edges;

symmetricEndNodes = [edges.EndNodes(:, 2), edges.EndNodes(:, 1)];
symmetricEdges = edges;
symmetricEdges.EndNodes = symmetricEndNodes;

digraphEdges = [edges; symmetricEdges];
aDigraph = digraph(digraphEdges, nodes);
end


function distanceTable = iCreateDistanceTable(internalDigraph)
% Given the digraph object, create a table summary.

digraphEdges = internalDigraph.Edges;
digraphNodes = internalDigraph.Nodes;
startVariant = digraphNodes.Variant(digraphEdges.EndNodes(:, 1));
endVariant = digraphNodes.Variant(digraphEdges.EndNodes(:, 2));

distanceTable = table(startVariant, endVariant, digraphEdges.Weight, digraphEdges.IsProximal);
distanceTable.Properties.VariableNames = {'StartVariant', 'EndVariant', 'Distance', 'IsProximal'};

numEdges = height(digraphEdges);
isBetweenCategories = false([numEdges, 1]);
getCategoriesOfNodeIndex = @(index) [digraphNodes.Attributes{index}.Category];

for k = 1:numEdges
    startCategories = getCategoriesOfNodeIndex(digraphEdges.EndNodes(k, 1));
    endCategories = getCategoriesOfNodeIndex(digraphEdges.EndNodes(k, 2));
    isBetweenCategories(k) = isempty(intersect(startCategories, endCategories));
end
distanceTable.IsBetweenCategories = isBetweenCategories;
end


function terminals = iSortEndVariantCouples(terminals)
% Given the list of couples of end variants, sort them one by one

couplesOfTerminals = num2cell(terminals, 2);
couplesOfTerminals = cellfun(@sort, couplesOfTerminals, ...
    UniformOutput=false);
terminals = table2array(cell2table(couplesOfTerminals));
end


function tf = iSelectVariantCouple(endNodes, firstVariants, secondVariants)
matchesFirst = ismember(endNodes, firstVariants);
matchesSecond = ismember(endNodes, secondVariants);
allMatches = [matchesFirst, matchesSecond];
tf = false;
if ...
        isequal(allMatches, [1, 0, 0, 1]) || ...
        isequal(allMatches, [0, 1, 1, 0]) || ...
        isequal(allMatches, [1, 1, 1, 1])
    tf = true;
end
end