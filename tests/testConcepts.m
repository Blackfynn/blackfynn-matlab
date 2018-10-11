classdef testConcepts < matlab.unittest.TestCase
    %TESTDATASETS Test class for testing datasets functionality
    
    properties
        bf
        ds
        testDatasetName = 'MatlabClientTestDataset'
    end
    
    methods (TestClassSetup)
        
        function createSession(testCase)
            p = path;
            testCase.addTeardown(@path, p);
            addpath('./..');
            testCase.bf = Blackfynn();
            testCase.ds = testCase.getOrCreateTestDataset(testCase.testDatasetName);
        end
    end
    
    methods (TestClassTeardown)
        
        function removeDataset(testCase)
            allDatasets = {testCase.bf.datasets.name};
            if any(strcmp(testCase.testDatasetName, allDatasets))
                testDataset = testCase.bf.datasets(strcmp(allDatasets, testCase.testDatasetName));
                testCase.bf.deleteDataset(testDataset,'force',true);
            end
        end
    end
    
    %% Test Method Block
    methods (Test)
        
        %% Test Function
        function testCreateModel(testCase)
            % Create a model
            testCase.ds.createModel('Patient','This is a patient model');
            testCase.verifyEqual(length(testCase.ds.models),1);
            testCase.verifyEqual(testCase.ds.models(1).name, 'Patient'); 
            
            model = testCase.ds.models(1);
            
            % Add a single property
            model.addProperties('prop 1','String', 'Property 1');
            prop = model.props(1);
            testCase.verifyEqual(prop.name, 'prop_1');
            testCase.verifyEqual(prop.displayName, 'prop 1');
            
            % Add a set of properties
            model.addProperties({'prop 2' 'prop 3'},{'Long' 'Double'}, {'Property 2' 'Property 3'});
            testCase.verifyEqual(model.nrProperties,3);
            testCase.verifyEqual(model.props(3).dataType,'Double');
            
            % Update a property
            
            
            % Delete a property
            
            
            
        end
        function testLinkingRecords(testCase)
        end
        
    end
    
    methods
        function ds = getOrCreateTestDataset(testCase, datasetName)
            ds = testCase.bf.datasets(strcmp({testCase.bf.datasets.name}, datasetName));
            if isempty(ds)
                ds = testCase.bf.createDataset(datasetName,'description dataset');
            end
        end
    end
end

