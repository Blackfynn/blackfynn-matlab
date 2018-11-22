classdef testFiles < matlab.unittest.TestCase
    %TESTDATASETS Test class for testing datasets functionality
    
    properties
        bf
        ds
        record
        testDatasetName = 'MatlabClientTestFilesDataset'
        testDatasetDescription = 'Description dataset'
    end
    
    methods (TestClassSetup)
        
        function getFiles(testCase)
            url = 'http://data.blackfynn.io/tutorials/example_data.zip';
            outfilename = websave('~/Downloads/testDownload.zip', url);
            unzip(outfilename, '~/Downloads');
        end
        
        function createSession(testCase)
            p = path;
            testCase.addTeardown(@path, p);
            addpath('./..');
            testCase.bf = Blackfynn();
            testCase.ds = testCase.getOrCreateTestDataset(testCase.testDatasetName);
            
            % Create model
            model = testCase.ds.createModel('Patient','This is a patient model');
            model.addProperty('prop 1','String', 'Property 1');
            
            % Create record
            params = struct(...
                'prop_1', 'This is a name');
            
            testCase.record = model.createRecords(params);
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
        function testUploadAndLink(testCase)
            testCase.ds.upload('.','include','test_data.txt','folder','testdata/folder');
            folder = testCase.ds.items;
            
            file = folder.items.items;
            testCase.verifyEqual(length(file), 1);
            testCase.verifyEqual(file.name,'test_data');
                        
            testCase.record.linkFiles(file);
            associatedFiles = testCase.record.getFiles();
            
            testCase.verifyEqual(length(associatedFiles), 1)
            
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

