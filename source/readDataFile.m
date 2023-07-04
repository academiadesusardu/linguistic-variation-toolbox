function dataTable = readDataFile(inputFile)
%READDATAFILE Read example JSON data files

% Copyright 2023 Acadèmia de su Sardu APS
dataTable = struct2table(jsondecode(fileread(inputFile)));
dataTable.Varieties = cellfun(@string, dataTable.Varieties, 'UniformOutput', false);
end

