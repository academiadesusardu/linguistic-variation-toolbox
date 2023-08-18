classdef VariantAttribute
    %VARIANTATTRIBUTE A class representing the attribute for a given
    %variant of a word.
    %
    % Syntax:
    %   A = VariantAttribute(V, IS)
    %       Create an attribute for the current variant that states:
    %       - it is attested for the category V
    %       - is is/it is not the standard for the current category.

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(SetAccess=immutable)
        % The variant's category
        Category

        % True if the variant is the standard version in the current given
        % category
        IsStandard
    end

    methods
        function obj = VariantAttribute(category, isStandard)
            %VARIANTATTRIBUTE Construct the object
            arguments
                category (1,1) {mustBeTextScalar}
                isStandard (1,1) logical
            end

            category = string(category);
            validateCategory(category);
            obj.Category = category;
            obj.IsStandard = isStandard;
        end
    end
end