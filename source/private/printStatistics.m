function printStatistics(aStruct, indentationLevel)
%PRINTSTATISTICS Recursively print a struct that contains statistics
%(structs, tables of data, ...)

% Copyright 2023 Acadèmia de su Sardu APS

allFieldNames = string(fields(aStruct));
fieldNameWidth = max(strlength(allFieldNames)) + 2;
padding = iPad(indentationLevel);

for k = 1:numel(allFieldNames)
    currField = allFieldNames(k);
    currFieldContent = aStruct.(currField);
    currFieldName = string(currField);
    currFieldNameFormat = padding + "%" + fieldNameWidth + "s";

    if isstruct(currFieldContent)
        disp(compose(currFieldNameFormat + ":\n", currFieldName));
        printStatistics(currFieldContent, indentationLevel + 1);
    elseif istable(currFieldContent)
        disp(compose(currFieldNameFormat + ":\n", currFieldName));
        problematicCol = "Attributes";
        if ismember(problematicCol, currFieldContent.Properties.VariableNames)
            currFieldContent = removevars(currFieldContent, problematicCol);
        end
        disp(iPrintTableToText(currFieldContent, indentationLevel + 1));
    else
        if isnan(currFieldContent)
            currFieldContent = iInvalidData();
        end
        disp(compose(currFieldNameFormat + ":  %s", ...
            currFieldName, ...
            string(currFieldContent)));
    end
end
end


function text = iPrintTableToText(aTable, indentationLevel)
[aTable, bottomLine] = iCleanTable(aTable); %#ok<ASGLU>
text = string(evalc('disp(aTable)'));

textLines = splitlines(eraseTags(text));
textLines(end) = [];
textLines = erase(textLines, regexpPattern('^\s\s'));

if ~isempty(bottomLine)
    textLines(end-1:end) = bottomLine;
end

text = join(iPad(indentationLevel) + textLines, newline);
end


function [aTable, bottomLine] = iCleanTable(aTable)
maxHeight = 20;
if height(aTable)>maxHeight
    bottomLine = ["..."; "Table is too long to display here. Only the first lines are shown."];
    aTable = aTable(1:maxHeight, :);
else
    bottomLine = [];
end

for k = 1:width(aTable)
    currColName = aTable.Properties.VariableNames{k};
    currCol = aTable.(currColName);
    isMissing = ismissing(currCol);
    if any(isMissing)
        currCol = string(currCol);
        currCol(isMissing) = iInvalidData();
        aTable.(currColName) = currCol;
    end
    if iscellstr(currCol)
        aTable.(currColName) = string(currCol);
    end
end
end


function padding = iPad(indentationLevel)
padding = string(repmat('  ', [1, indentationLevel]));
end


function message = iInvalidData()
message = "Invalid data";
end