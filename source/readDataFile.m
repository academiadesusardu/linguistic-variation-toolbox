function dataTable = readDataFile(inputFile)
%READDATAFILE Read example JSON data files.
%
% Example:
%   data = readDataFile("../data/gennàrgiu.json");

% Copyright 2023 Acadèmia de su Sardu APS
dataTable = struct2table(jsondecode(fileread(inputFile)));
dataTable.Categories = cellfun(@string, dataTable.Categories, 'UniformOutput', false);
end

