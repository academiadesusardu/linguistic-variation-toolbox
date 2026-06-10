classdef VariantAttribute
    %VARIANTATTRIBUTE A class representing the attribute for a given
    %variant of a word.
    %
    % Syntax:
    %   A = VariantAttribute(V, IS)
    %       Create an attribute for the current variant that states:
    %       - it is attested for the category V
    %       - is is/it is not the reference for the current category.

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(SetAccess=immutable)
        % The variant's category
        Category

        % True if the variant is the reference the current given category.
        IsCategoryReference
    end

    methods
        function obj = VariantAttribute(category, isCategoryReference)
            %VARIANTATTRIBUTE Construct the object
            arguments
                category (1,1) {mustBeTextScalar}
                isCategoryReference (1,1) logical
            end

            category = string(category);
            validateCategory(category);
            obj.Category = category;
            obj.IsCategoryReference = isCategoryReference;
        end
    end
end