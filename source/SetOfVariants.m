classdef SetOfVariants < handle
    %SETOFVARIANTS A set of variants of the same word.
    %
    %   G = SetOfVariants(VN, VR)
    %       Construct the object given:
    %           - The array of variants VN
    %           - The corresponding categories VR
    %       To determine the statistics, use a simple Levenshtein distance.
    %
    %   G = SetOfVariants(VN, VR, S)
    %       Construct the object given VN, VR, and:
    %           - a logical array S stating whether the variant
    %             is the category's reference or not.
    %       To determine the statistics, use a simple Levenshtein distance.
    %
    %   G = SetOfVariants(VN, VA)
    %       Construct the object given VN and:
    %           - a cell array of variant attributes VA specifying the
    %             attributes of every variant in VN.
    %       To determine the statistics, use a simple Levenshtein distance.
    %
    %   G = SetOfVariants(__, DistanceFunction=F)
    %       Construct the object with the syntax(es) in the previous examples,
    %       but also specify a custom distance function.
    %
    %
    % SetOfVariants properties:
    %   VariantTable     - A summary of all the data about the variants.
    %   DistanceTable    - All distances between variants.
    %   DistanceFunction - The metric used to compute distances.
    %
    % SetOfVariants methods:
    %   getNumberOfVariants     - Get the number of variants represented by
    %                             the current object.
    %   isCategoryReference     - Given a variant, check if it is the
    %                             category's referene.
    %   getDistanceBetween      - Get the distance between two or more variants
    %                             according to the DistanceFunction metric.
    %   getCategoriesOf         - Get the categories of one or more variants.
    %   getCategoryReferenceIn  - Get the reference in a given category.
    %   getVariantsIn           - Get the variants in a given category.
    %   computeStatistics       - Compute some statistics on the given set of
    %                             variants and display them to screen.
    %   plot                    - Visually represent the set of variants as a
    %                             graph.
    %   plotDistances           - Represent the distances between variants in
    %                             the current object using boxplots.
    %
    % Example:
    %   allCategories(["camp", "log"]);
    %   variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"];
    %   categories = {"camp", "log", "log"};
    %   isCategoryReference = [true, false, true];
    %   set = SetOfVariants(variants, categories, isCategoryReference);
    %   plot(set);

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(SetAccess=immutable)
        % The distance function that was used to compute the statistics
        DistanceFunction
    end

    properties(Dependent)
        % All the data that was provided about the variants
        VariantTable

        % All the data that was computed about the distances
        DistanceTable
    end

    properties(Access=private)
        % Internal graph object used for statistics and plotting
        InternalGraph

        % Internal digraph object used for statistics and plotting
        InternalDigraph
    end


    methods
        function obj = SetOfVariants(variants, categoriesOrAttributes, isCategoryReference, options)
            %VARIANTSSET Construct an object representing a set of
            % variants of the same word
            arguments
                variants {mustBeText}
                categoriesOrAttributes cell
                isCategoryReference logical = false(length(variants), 1)
                options.DistanceFunction (1,1) function_handle = @simpleLevenshtein
            end
            variants = reshape(string(variants), [], 1);
            assert(numel(unique(variants))==numel(variants), ...
                "The elements in the variant array are not unique.")

            [attributes, isCategoryReference] = ...
                iComputeAttributes(categoriesOrAttributes, isCategoryReference);

            dataTable = table(variants, attributes, isCategoryReference);
            dataTable.Properties.VariableNames = {'Name', 'Attributes', 'IsCategoryReference'};

            obj.DistanceFunction = options.DistanceFunction;

            nodesTable = iCreateNodesTable(dataTable);
            edgesTable = iCreateEdgesTable(dataTable, obj.DistanceFunction);
            obj.InternalGraph = graph(edgesTable, nodesTable);

            obj.InternalDigraph = iGraphToDigraph(obj.InternalGraph);
            obj.InternalDigraph.Edges.IsProximal = iFindProximalNodes(obj.InternalDigraph);

            obj.checkCategoryReferences();
        end


        function data = get.VariantTable(obj)
            % Compute the variant table that can be used by the
            % user.
            internalData = obj.InternalGraph.Nodes;
            data = renamevars(internalData, {'Name'}, {'Variant'});
        end


        function data = get.DistanceTable(obj)
            % Compute the table of distances that can be displayed by the
            % user.
            internalData = obj.InternalDigraph.Edges;
            internalData.FromVariant = internalData.EndNodes(:, 1);
            internalData.ToVariant = internalData.EndNodes(:, 2);
            internalData = removevars(internalData, {'EndNodes'});
            internalData = movevars(internalData, {'Weight'}, After={'ToVariant'});
            internalData = movevars(internalData, {'IsProximal'}, After={'Weight'});
            data = internalData;
        end


        function numVariants = getNumberOfVariants(obj)
            %GETNUMBEROFVARIANTS Get the total number of variants
            %
            % Syntax:
            %   N = getNumberOfVariants(S)
            %       Return the number of variants
            numVariants = numnodes(obj.InternalGraph);
        end


        function variants = getAllVariants(obj)
            %GETALLVARIANTS Get all the variants in the set
            %
            % Syntax:
            %   V = getAllVariants(S)
            %       Return all the variants
            variants = string(obj.InternalGraph.Nodes.Name);
        end


        function categories = getCategoriesOf(obj, variant)
            %GETVARIETIESOF Get the categories of a given variant.
            %
            % Syntax:
            %   C = getCategoriesOf(S, V)
            %       Get the categories of the given variant V.
            arguments
                obj (1,1)
                variant (1, 1) string
            end
            variantIndex = obj.InternalGraph.findnode(variant);
            assert(variantIndex~=0, "The variant is not in the set.");

            variantAttributes = obj.InternalGraph.Nodes.Attributes{variantIndex};
            categories = [variantAttributes.Category];
        end


        function variants = getVariantsIn(obj, category)
            %GETVARIANTSIN Get the variants that belong to the given
            %category.
            %
            % Syntax:
            %   V = getVariantsIn(S, C)
            %       Get the variants in category C.
            arguments
                obj (1,1)
                category (1, 1) string
            end
            validateCategory(category);

            allVariants = obj.getAllVariants();
            categoriesPerVariant = arrayfun(@(v) obj.getCategoriesOf(v), ...
                allVariants, ...
                UniformOutput=false);
            isOfThisCategory = cellfun(@(categories) ismember(category, categories), ...
                categoriesPerVariant, ...
                UniformOutput=true);
            variants = allVariants(isOfThisCategory);
        end


        function tf = isCategoryReference(obj, variant)
            %ISCATEGORYREFERENCE Return true if the given variant the reference of
            %one or more categories.
            %
            % Syntax:
            %   TF = isCategoryReference(S, V)
            %       Check if variant V is a reference.
            arguments
                obj (1,1)
                variant (1, 1) string
            end
            variantIndex = obj.InternalGraph.findnode(variant);
            assert(variantIndex~=0, "The variant is not in the set.");

            variantAttributes = obj.InternalGraph.Nodes.Attributes{variantIndex};
            tf = any([variantAttributes.IsCategoryReference]);
        end


        function references = getCategoryReferenceIn(obj, category)
            %GETCATEGORYREFERENCEIN Get the reference variant in the given category.
            %
            % Syntax:
            %   S = getCategoryReferenceIn(S, C)
            %       Get the reference variant in category C.
            arguments
                obj (1,1)
                category (1, 1) string
            end
            validateCategory(category);

            isThisCategoryReference = isCategoryReferenceIn(obj.InternalGraph, category);
            references = string(obj.InternalGraph.Nodes.Name(isThisCategoryReference));
        end


        function uniqueDistances = getDistanceBetween(obj, firstVariants, secondVariants)
            %GETDISTANCEBETWEEN Given two sets of variants, get the distances
            %between them, but count the distance between two variants only
            %once.
            %
            % Syntax:
            %   D = getDistanceBetween(S, V1, V2)
            %       Get the distance between all the variants in V1 and all
            %       the variants in V2.

            numFirstVariants = numel(firstVariants);
            uniqueDistances = cell(numFirstVariants, 1);
            for ii = 1:numel(firstVariants)
                currFirstVariant = repmat(firstVariants(ii), size(secondVariants));
                currEdgeIndices = obj.InternalGraph.findedge(currFirstVariant, secondVariants);
                currEdgeIndices(currEdgeIndices==0) = [];

                uniqueDistances{ii} = obj.InternalGraph.Weight(currEdgeIndices);
            end
            uniqueDistances = cell2num(uniqueDistances);
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
            %       multi-dimensional scaling. By default, it's "mds".
            arguments
                obj (1,1)
                options.CenterCategories (1, 2) string
                options.Mode (1, 1) = getCompletePlotModeString()
                options.PlacementAlgorithm (1, 1) = getMdsPlacementAlgorithmString()
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
                    currData = obj.InternalGraph.Edges.Weight;
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
                            obj.getDistanceBetween(...
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
        end


        function stats = computeStatistics(obj, options)
            %COMPUTESTATISTICS Compute the statistics over the input data.
            %
            % Syntax:
            %   ST = computeStatistics(S)
            %       Print all all the statistics about the SetOfVariants object
            %       S and return them as a struct.
            %
            %   S = computeStatistics(__, Quiet=Q)
            %       Return the statistics but do not print them out to
            %       screen. Q is false by default.
            arguments
                obj (1,1)
                options.Quiet (1, 1) logical = false
            end

            categories = allCategories();
            numCategories = length(categories);
            stats = struct();

            stats.WholeGraph = computeCategoryStatistics( ...
                obj.InternalGraph, []);
            for k = 1:numCategories
                currCategory = categories(k);
                stats.("Category" + currCategory) = computeCategoryStatistics( ...
                    obj.InternalGraph, currCategory);
            end

            if ~options.Quiet
                printStatistics(stats, 0);
            end
        end
    end

    methods(Access=private)
        function checkCategoryReferences(obj)
            % Check that there is max one category reference per category

            categories = allCategories();
            for k = 1:numel(categories)
                categoryReference = obj.getCategoryReferenceIn(categories(k));
                assert(numel(categoryReference)<=1, ...
                    "There can be only reference per category");
            end
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
            dataTable.Name(ii), dataTable.Name(jj));
        k = k+1;
    end
end

edgesTable = table(endNodes, weights, ...
    VariableNames=["EndNodes", "Weight"]);
end


function nodeTable = iCreateNodesTable(dataTable)
% Create the table of nodes for the plot

nodeTable = dataTable(:, {'Name', 'Attributes', 'IsCategoryReference'});
end


function [attributes, isActuallyCategoryReference] = iComputeAttributes(categoriesOrAttributes, isCategoryReference)
% Compute all the attributes of the variants

inputLength = length(categoriesOrAttributes);
attributes = cell(inputLength, 1);
isActuallyCategoryReference = false(inputLength, 1);

for k = 1:inputLength
    currElement = categoriesOrAttributes{k};
    currElementAttributes = [];

    for j = 1:length(currElement)
        currAttribute = currElement(j);
        if isstring(currAttribute)
            validateCategory(currAttribute);

            currElementIsCategoryReference = isCategoryReference(k);
            attributeToAdd = VariantAttribute(...
                currAttribute, ...
                currElementIsCategoryReference);
        elseif isa(currAttribute, 'VariantAttribute')
            attributeToAdd = currAttribute;
        else
            error("Invalid specification of the attributes of variant number %d: the input should be a cell array, where each cell contains either an array of strings or an array of VariantAttribute objects.", k);
        end
        currElementAttributes = [currElementAttributes; attributeToAdd]; %#ok<AGROW>
    end
    currElementIsActuallyCategoryReference = any([currElementAttributes.IsCategoryReference]);

    attributes{k} = currElementAttributes;
    isActuallyCategoryReference(k) = currElementIsActuallyCategoryReference;
end
end


function isProximal = iFindProximalNodes(directGraph)
% Compute edges that won't show in the final graph

isProximal = false(directGraph.numedges(), 1);
weights = directGraph.Edges.Weight;

for ii = 1:directGraph.numnodes()
    currNode = string(directGraph.Nodes.Name{ii});

    outEdgesIdx = directGraph.outedges(currNode);
    if ~any(outEdgesIdx)
        continue;
    end

    outEdgesWeights = weights(outEdgesIdx);
    weightsOfInterest = outEdgesWeights==min(outEdgesWeights);
    currProximal = outEdgesIdx(weightsOfInterest);
    isProximal(currProximal) = true;
end
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