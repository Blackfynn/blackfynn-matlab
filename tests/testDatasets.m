classdef testDatasets < matlab.unittest.TestCase
    %TESTDATASETS Test class for testing datasets functionality
    
    properties
        bf
        testDatasetName = 'MatlabClientTestDataset'
        testDatasetDescription = 'Description dataset'
    end
    
    methods (TestClassSetup)
        
        function createSession(testCase)
            p = path;
            testCase.addTeardown(@path, p);
            addpath('./..');
            testCase.bf = Blackfynn();
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
        function testCreateDeleteDataset(testCase)
            allDatasets = {testCase.bf.datasets.name};
            if any(strcmp(testCase.testDatasetName, allDatasets))
                testDataset = testCase.bf.datasets(strcmp(allDatasets, testCase.testDatasetName));
                success = testCase.bf.deleteDataset(testDataset,'force',true);
                testCase.verifyEqual(true, success);
            end
            
            ds = testCase.bf.createDataset(testCase.testDatasetName,testCase.testDatasetDescription);
            verifyEqual(testCase,ds.name,testCase.testDatasetName);
            verifyEqual(testCase,ds.description,testCase.testDatasetDescription);
            
            success = testCase.bf.deleteDataset(ds,'force',true);
            testCase.verifyEqual(true, success);
        end
        
        function testUpdateDataset(testCase)
            ds = getOrCreateTestDataset(testCase, testCase.testDatasetName);
            verifyEqual(testCase,ds.name,testCase.testDatasetName);
            
            ds_updated = getOrCreateTestDataset(testCase, 'MatlabClientTestDataset_updated');
            if ~isempty(ds_updated)
                success = testCase.bf.deleteDataset(ds_updated,'force',true);
                testCase.verifyEqual(true, success);
            end
            
            % Change property values
            ds.name = 'MatlabClientTestDataset_updated';
            ds.description = 'Description dataset_updated';
            
            ds.update();
            
            bf2 = Blackfynn();
            allNames = {bf2.datasets.name};
            hasUpdatedName = find(strcmp(allNames,'MatlabClientTestDataset_updated'),1);
            verifyTrue(testCase, ~isempty(hasUpdatedName));
            verifyEqual(testCase, bf2.datasets(hasUpdatedName).description,'Description dataset_updated');
            
            % Revert to default property values
            ds.name = testCase.testDatasetName;
            ds.description = testCase.testDatasetDescription;
            ds.update();
   
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

