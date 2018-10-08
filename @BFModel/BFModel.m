classdef BFModel < BFBaseModelNode
    %BFMODEL A metadata model on the Blackfynn platform 
    %   The BFModel class represents metadatamodels on the Blackfynn
    %   platform. Users can create models to define how metadata is
    %   organized within a dataset. Users can then create records for each
    %   of these models and link records to eachother.
    
    properties
        nrRecords = 0           % Number of records for this model
        props = []              % Array of property details
    end
    
    properties (Hidden)
        nrProperties = 0        % Number of properties in the model
    end

    methods
        function obj = BFModel(varargin)
            %BFBASEMODELNODE Construct an instance of this class
            %   args = [session, id, name, dataset_id, display_name,
            %           description, locked, created_at, updated_at]
            obj = obj@BFBaseModelNode(varargin{:});
        end
        function records = getRecords(obj, varargin)
            %GETRECORDS Returns records of the given model
            %   RECORDS = GETRECORDS(OBJ) returns the first 100 records for the
            %   given model.
            %   RECORDS = GETALL(OBJ, MAXCOUNT, OFFSET) returns a total of
            %   MAXCOUNT records starting at an OFFSET from the first
            %   record. You can use this to iteratively request many
            %   records.
            %
            %   Example:
            %
            %       M1 = BF.models(1);
            %       RECORDS = M1.GETALL()
            %
            %   See also:
            %       BFRecord, BFDataset
            
            maxCount = 100;
            offset = 0;
            
            if nargin > 1
                narginchk(2,2);
                maxCount = varargin{1};
                offset = varargin{2};
            end
            
            records = obj.session.conceptsAPI.getRecords(obj.datasetId, ...
                obj.id, maxCount, offset);

        end
        function records = createRecords(obj, data)
            %CREATE  Create a record for a particular model
            %   RECORDS = CREATE(OBJ, DATA) creates a
            %   record of type MODEL and populate the record with the
            %   provided values where MODEL is of type BFModel. DATA is
            %   a matlab structure with the model property names and their
            %   values. If DATA is an array of structs, multiple objects
            %   will be created and returned.
            %
            %   The property names and the property value types in the DATA
            %   struct should match the property names and value types of
            %   the selected model.
            %
            %   For example:
            %       person = dataset.models(1);
            %       data(1) = struct('name', 'Joe', 'age', 23);
            %       data(2) = struct('name', 'Emily', 'age', 27);
            %       person.createRecord(data);
            %
            %   See also:
            %       BFModel.getall
                        
            assert(isa(data,'struct'));
            
            % validate property names
            providedProps = fieldnames(data(1));
            if ~all(cellfun(@(x) any(strcmp(x,{obj.props.name})), providedProps))
                fprintf(2, 'incorrect property names for object of type: %s\n', upper(obj.displayName));
                return
            end
            
            % validate property types
            records = obj.session.conceptsAPI.createRecords(obj.datasetId, obj.id, data);
            
        end
        function success = deleteRecords(obj, records)
            
            if ~isa(records, 'BFRecord')
                error('Need to supply records of type @BFRecord');
            end
            
            recordIds = {records.id};
            success = obj.session.conceptsAPI.deleteRecords(obj.datasetId, obj.id, recordIds);
            
            % delete matlab objects if platform delete is successfull
            for i=1:length(records)
                if any(strcmp(records(i).id, success))
                    delete(records(i));
                end
            end
            
            % let user know if delete failed 
            if length(success) ~= length(records)
                diff_l = length(records)-length(success);
                fprintf(2, '%i our of %i records could not be deleted. This could be because the records no longer exist on the platform.', diff_l, length(records));
            end
            
        end
        function obj = addProperties(obj, name, dataType, description, varargin)
            %ADDPROPERTY  Adds a property to a specific model
            %   OBJ = ADDPROPERTY(OBJ, 'Name', 'Datatype', 'Description')
            %   add a single property to the model OBJ. 
            %   OBJ = ADDPROPERTY(OBJ, NAME, DATATYPE, DESCRIPTION) adds
            %   one of more properties to the current model OBJ. 
            %
            %   The 'Datatype' for each property has to be one of: ["String`",
            %   "Boolean", "Date", "Number", or "Decimal"].
            %
            %   This function automatically sets the first property of a
            %   model to be the 'Concept Title'. This can be modified in
            %   the web-application.
            
            
            % Check inputs
            if nargin < 4
                error('Incorrect number of input arguments.')
            end
            
            multiprop = false;
            if isa(name,'char')
                assert(isa(description,'char') && isa(dataType,'char'), 'When adding single property, input variables for name, datatype,and description need to be of type ''char''');
            else
                assert(isa(name,'cell'), 'When adding multiple properties, name, datatype and description input variables need to be of type cell-array');
                assert(length(name) == length(dataType) && length(dataType)==length(description), 'All input variables need to be cell arrays with the same length.');
                multiprop = true;
            end
            
            % Get existing properties from webservice
            existingProps = obj.session.conceptsAPI.getProperties(obj.datasetId, obj.id);
            
            % Set concept title if no other properties yet.
            setConceptTitle = true;
            if ~isempty(existingProps)
                setConceptTitle = false;
            end
            
            newProps = struct();
            if multiprop
                for i=1:length(name)
                    assert(any(strcmp(dataType{i},{'String' 'Boolean', 'Date', 'Double', 'Long'})), ...
                    'Datatype needs to be one of: [''Text'' ''Boolean'', ''Date'', ''Double'', ''Long''. ');
                
                    newProps(i).conceptTitle = setConceptTitle;
                    newProps(i).dataType = dataType{i};
                    newProps(i).default = true;
                    newProps(i).description = "";
                    newProps(i).displayName = name{i};
                    newProps(i).locked = false;
                    newProps(i).name = BFConceptsAPI.slugFromString(name{i});
                    newProps(i).value = "";
                    
                    setConceptTitle = false;
                end
                
            else
                assert(any(strcmp(dataType,{'String' 'Boolean', 'Date', 'Double', 'Long'})), ...
                    'Datatype needs to be one of: [''Text'' ''Boolean'', ''Date'', ''Double'', ''Long''. ');
                newProps.conceptTitle = setConceptTitle;
                newProps.dataType = dataType;
                newProps.default = true;
                newProps.description = "";
                newProps.displayName = name;
                newProps.locked = false;
                newProps.name = BFConceptsAPI.slugFromString(name);
                newProps.value = "";
                
            end
                        
            resp = obj.session.conceptsAPI.updateModelProperties(...
                obj.datasetId, obj.id, existingProps, newProps);
            
            if resp.StatusCode == matlab.net.http.StatusCode.BadRequest
                error('There was an error creating the property, does another property with the same name already exist?');
            end
            
            obj.props = BFModelProperty.createFromResponse(resp.Body.Data, obj.session);
            obj.nrProperties = length(obj.props);
             
        end
    end
    
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,class(obj));
            else
                s = '';
            end
        end
        function records = handleGetRecords(obj,resp)
            records = BFRecord.empty(length(resp),0);
            for i=1: length(resp)
                records(i) = BFRecord.createFromResponse(resp(i), obj.session, obj.id, obj.datasetId);
            end
        end
        function props = getProperties(obj)
            
            props = obj.session.conceptsAPI.getProperties(obj.datasetId, obj.id);
            
        end
    end
    
    methods (Static)
        function out = createFromResponse(resp, session, datasetid)
          %CREATEFROMRESPONSE  Create object from server response
          % args = [session, id, name, display_name,
            %           description, locked, created_at, updated_at ]  
          
          out = BFModel(session, resp.id, resp.name, ...
              resp.displayName, resp.description, resp.locked,...
              resp.createdAt, resp.updatedAt);
          out.nrRecords = resp.count;
          out.nrProperties = resp.propertyCount;
          out.datasetId = datasetid;
          out.props = out.getProperties();
          
        end
    end
end

