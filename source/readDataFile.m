function dataSet = readDataFile(inputFile)
%READDATAFILE Read example JSON data files.
%
% Example:
%   data = readDataFile("../data/gennàrgiu.json");

% Copyright 2023 Acadèmia de su Sardu APS

jsonContent = jsondecode(fileread(inputFile));
if numel(jsonContent)==1
    jsonContent = struct2cell(jsonContent);
    dataSet = cellfun(@iStruct2SetOfVariants, jsonContent);
else
    dataSet = iStruct2SetOfVariants(jsonContent);
end
end


function outSet = iStruct2SetOfVariants(inStruct)
% Convert the input struct to a SetOfVariants object.
if isfield(inStruct, "Attributes")
    tempTable = struct2table(inStruct, AsArray=true);
    if isstruct(tempTable.Attributes)
        tempTable.Attributes = num2cell(tempTable.Attributes);
    end
    tempTable.Attributes = cellfun(@iStruct2Attributes, tempTable.Attributes, ...
        UniformOutput=false);
    outSet = SetOfVariants(tempTable.Variant, tempTable.Attributes);
else
    tempTable = struct2table(inStruct);
    tempTable.Categories = cellfun(@string, tempTable.Categories, ...
        UniformOutput=false);
    outSet = SetOfVariants(tempTable.Variant, tempTable.Categories, tempTable.IsCategoryReference);
end
end


function attributes = iStruct2Attributes(attributeStructs)
% Convert an array of attribute structs to an array of VariantAttribute
attributes = arrayfun(@(s) VariantAttribute(string(s.Category), logical(s.IsCategoryReference)), ...
    attributeStructs, ...
    UniformOutput=true);
end