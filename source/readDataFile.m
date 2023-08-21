function dataSet = readDataFile(inputFile)
%READDATAFILE Read example JSON data files.
%
% Example:
%   data = readDataFile("../data/gennàrgiu.json");

% Copyright 2023 Acadèmia de su Sardu APS

jsonContent = jsondecode(fileread(inputFile));
if numel(jsonContent)==1
    jsonContent = struct2cell(jsonContent);
    dataSet = cellfun(@iStruct2VariantsSet, jsonContent);
else
    dataSet = iStruct2VariantsSet(jsonContent);
end
end


function outSet = iStruct2VariantsSet(inStruct)
% Convert the input struct to an output table of the expected format.
if isfield(inStruct, "Attributes")
    tempTable = struct2table(inStruct, AsArray=true);
    if isstruct(tempTable.Attributes)
        tempTable.Attributes = num2cell(tempTable.Attributes);
    end
    tempTable.Attributes = cellfun(@iStruct2Attributes, tempTable.Attributes, ...
        UniformOutput=false);
    outSet = VariantsSet(tempTable.Variant, tempTable.Attributes);
else
    tempTable = struct2table(inStruct);
    tempTable.Categories = cellfun(@string, tempTable.Categories, ...
        UniformOutput=false);
    outSet = VariantsSet(tempTable.Variant, tempTable.Categories, tempTable.IsStandard);
end
end


function attributes = iStruct2Attributes(attributeStructs)
% Convert an array of attribute structs to an array of VariantAttribute
attributes = arrayfun(@(s) VariantAttribute(string(s.Category), logical(s.IsStandard)), ...
    attributeStructs, ...
    UniformOutput=true);
end