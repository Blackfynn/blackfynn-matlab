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
            testCase.assertEqual(length(testCase.ds.models),1);
            testCase.assertEqual(testCase.ds.models(1).name, 'Patient'); 
            model = testCase.ds.models(1);
            
            % Add a single property
            prop = model.addProperty('prop 1','String', 'Property 1');
            testCase.verifyEqual(prop.name, 'prop_1');
            testCase.verifyEqual(prop.displayName, 'prop 1');
            testCase.verifyEqual(prop.default, false);
            testCase.verifyEqual(length(model.props), 1);
            
            % Add property with multiple values for String
            prop = model.addProperty('prop 2', 'String', 'String Info', 'mult', true);
            testCase.verifyEqual(prop.dataType.type, 'array');
            testCase.verifyEqual(length(model.props), 2);

            % Add property with enumerated values for String 
            prop = model.addProperty('prop 3', 'String', 'String Info', 'enum', {'1' '2' '3'});
            testCase.verifyEqual(prop.dataType.type, 'array');
            testCase.verifyEqual(prop.dataType.items.enum, {'1'; '2'; '3'});
            testCase.verifyEqual(length(model.props), 3);
            
            % Add property with enumerated values for Double 
            prop = model.addProperty('prop 4', 'Double', 'Double Info', 'enum', [1 2 3]);
            testCase.verifyEqual(prop.dataType.type, 'array');
            testCase.verifyEqual(prop.dataType.items.enum, [1; 2; 3]);
            testCase.verifyEqual(length(model.props), 4);

            % Add property with enumerated values for Long 
            prop = model.addProperty('prop 5', 'Long', 'Long Info', 'enum', int64([1 2 3]));
            testCase.verifyEqual(prop.dataType.type, 'array');
            testCase.verifyEqual(prop.dataType.items.enum, [1; 2; 3]);
            testCase.verifyEqual(length(model.props), 5);

            % Add a required property
            prop = model.addProperty('prop 6','String', 'Property 1','required', true);
            testCase.verifyEqual(prop.default, true);
            testCase.verifyEqual(length(model.props), 6);
            
        end
        
        function createRecords(testCase)
            
            % Create record setting only one property
            record = struct(...
                'prop_6', 'This is a name');
            
            m = testCase.ds.models(1);
            result = m.createRecords(record);
            testCase.verifyEqual(result.prop_6, 'This is a name');
            
            % Create record for model with multiple properties
            record = struct(...
                'prop_1', 'this is a string', ...
                'prop_3', '1', ...
                'prop_4', 4, ... 
                'prop_6', 'This is a name');
            record.prop_2 = {'string 1' 'string2'};
            
            m = testCase.ds.models(1);
            result = m.createRecords(record);
            
            testCase.verifyEqual(result.prop_6, 'This is a name');
            
            % Create multiple records with multiple properties
            
            
            
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

