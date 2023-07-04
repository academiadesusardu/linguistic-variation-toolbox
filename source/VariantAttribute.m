classdef VariantAttribute
    %VARIANTATTRIBUTE A class representing the attribute for a given
    %variant of a word.
    %
    % Syntax:
    %   A = VariantAttribute(V, IS)
    %       Create an attribute for the current variant that states:
    %       - it is attested for the variety V
    %       - is is/it is not the standard for the current variety.

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(SetAccess=immutable)
        % The variant's variety
        Variety

        % True if the variant is the standard version in the current given
        % variety
        IsStandard
    end

    methods
        function obj = VariantAttribute(variety, isStandard)
            %VARIANTATTRIBUTE Construct the object
            arguments
                variety (1,1) {mustBeTextScalar}
                isStandard (1,1) logical
            end

            variety = string(variety);
            assert(ismember(variety, allVarieties()), ...
                "This variety should belong to the set of varieties.");
            obj.Variety = variety;
            obj.IsStandard = isStandard;
        end
    end
end