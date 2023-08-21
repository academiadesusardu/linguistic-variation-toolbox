classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture(fullfile('..', 'source'))}) ...
        TestSetOfVariantsConstructorWorkflow < matlab.unittest.TestCase
    %TESTSETOFVARIANTSCONSTRUCTORWORKFLOW Workflow tests for the SetOfVariants class

    % Copyright 2023 Acadèmia de su Sardu APS

    properties(TestParameter)
        DataFile = struct( ...
            'Ochisorzu', {fullfile(iDataFolder(), "ochisorzu.json")}, ...
            'Gennargiu', {fullfile(iDataFolder(), "gennàrgiu.json")}, ...
            'Benturgiu', {fullfile(iDataFolder(), "bentùrgiu.json")}, ...
            'Simple',    {fullfile(iDataFolder(), "ochisorzu.json")});
    end

    methods(TestClassSetup)
        function setCategories(testCase) %#ok<MANU> 
            % Set categories that are common to all the example data files.
            allCategories(["L", "C"]);
        end
    end

    methods(Test)
        function checkCreationSuccesful(testCase, DataFile)
            % Check that some VariantSet objects are succesfully created.
            testCase.verifyWarningFree(@() readDataFile(DataFile), ...
                "Error while reading a data file.");
        end
    end
end

function fld = iDataFolder()
fld = fullfile("..", "data");
end