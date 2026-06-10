function validateCategory(category)
%VALIDATECATEGORY Ensure that the given category is valid given the current
%configuration.

% Copyright 2023 Acadèmia de su Sardu APS

assert(ismember(category, allCategories()), ...
    "The input category is not among those defined in 'allCategories'.")
end
