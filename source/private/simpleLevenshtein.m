function distance = simpleLevenshtein(first, second)
%SIMPLELEVENSHTEIN Simplified function to compute the distance between two
%variants based on the Levenshtein distance.

% Copyright 2023 Acadèmia de su Sardu APS
first = iReplaceDiacritics(first);
second = iReplaceDiacritics(second);
distance = levenshteinCore(first, second);
end

function replaced = iReplaceDiacritics(inString)
% Replace all the characters with diacritic-less characters as specified in
% the the replacement table.
replaced = inString;
replacementTable = iReplacementTable();
for k = 1:height(replacementTable)
    substituteTo = replacementTable.After(k);
    listOfCharctersToSubstitute = replacementTable.Before{k};

    for c = 1:length(listOfCharctersToSubstitute)
        currCharacterToSubstitute = listOfCharctersToSubstitute(c);
        replaced = replace(replaced, currCharacterToSubstitute, substituteTo);
    end
end
end

function tbl = iReplacementTable()
conversionData = ...
    {'a', 'àá' ; ...
    'e', 'èé' ; ...
    'i', 'ìíï'; ...
    'o', 'òó' ; ...
    'u', 'ùú' ; ...
    'A', 'ÀÁ' ; ...
    'E', 'ÈÉ' ; ...
    'I', 'ÌÍ' ; ...
    'O', 'ÒÓ' ; ...
    'U', 'ÙÚ'};
tbl = table(cell2mat(conversionData(:, 1)), conversionData(:, 2), ...
    VariableNames={'After', 'Before'});
end
