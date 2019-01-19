classdef BFModel < BFBaseSchemaNode
    %BFMODEL A metadata model on the Blackfynn platform 
    %   The BFModel class represents metadatamodels on the Blackfynn
    %   platform. Users can create models to define how metadata is
    %   organized within a dataset. Users can then create records for each
    %   of these models and link records to eachother.
    
    properties
        nrRecords = 0           % Number of records for this model
        props = []              % Array of property details
        locked = false
    end
    
    properties (Hidden)
        nrProperties = 0        % Number of properties in the model
    end

    properties (Dependent)
        relationships           % Relationships available for the model
    end
    
    properties (Access = private)
        relationships_
        relationshipChecked = false
    end
    
    methods
        function obj = BFModel(session, dataset, id, name, displayName, ...
                description, locked)
              %BFMODEL Construct an instance of this class
            %   OBJ = BFMODEL(SESSION, DATASET, 'id', 'name', 'displayName',
            %   'description', LOCKED) creates an object of class BFMODEL.
            
            obj = obj@BFBaseSchemaNode(session, dataset, id, name, displayName, ...
                description);
            
            obj.locked = locked;
            
        end
        
        function value = get.relationships(obj)                         
            % GET_RELATIONSHIPS gets and caches the models for dataset.
            
            if obj.relationshipChecked
                value = obj.relationships_;
            else
                response = obj.session_.conceptsAPI.getRelationships(obj.dataset.id_, obj.id_);
                value = BFRelationship.createFromResponse(response, obj.session_, obj.dataset);
                obj.relationships_ = value;
                obj.relationshipChecked = true;
            end
            
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
                narginchk(3,3);
                maxCount = varargin{1};
                offset = varargin{2};
            end
            
            response = obj.session_.conceptsAPI.getRecords(obj.dataset.id_, ...
                obj.id_, maxCount, offset);
            
            records = BFRecord.empty(length(response),0);
            for i=1: length(response)
                records(i) = BFRecord.createFromResponse(response(i), ...
                    obj.session_, obj, obj.dataset);
            end

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
            if ~all(cellfun(@(x) any(strcmpi(x,{obj.props.name})), providedProps))
                fprintf(2, 'incorrect property names for object of type: %s\n', upper(obj.name));
                return
            end
                        
            % validate property types
            records = obj.session_.conceptsAPI.createRecords(obj.dataset, obj, data);
            
        end
        
        function success = deleteRecords(obj, records)                  
            % DELETERECORDS Deletes records from the platform
            %   SUCCESS = DELETERECORDS(OBJ, RECORDS) deletes the RECORDS
            %   from the platform. RECORDS is an object, or an array of
            %   objects of type BFRECORD which should belong to the current
            %   model.
            %
            %   For example:
            %       M = dataset.models(1);
            %       RECORDS = M.getRecords();
            %       M.DELETERECORDS(RECORDS(1:10);
            
            if ~isa(records, 'BFRecord')
                error('Need to supply records of type @BFRecord');
            end
            
            recordIds = {records.id_};
            success = obj.session_.conceptsAPI.deleteRecords(obj.dataset.id_, obj.id_, recordIds);
            
            % delete matlab objects if platform delete is successfull
            for i=1:length(records)
                if any(strcmp(records(i).id_, success))
                    delete(records(i));
                end
            end
            
            % let user know if delete failed 
            if length(success) ~= length(records)
                diff_l = length(records)-length(success);
                fprintf(2, '%i our of %i records could not be deleted. This could be because the records no longer exist on the platform.', diff_l, length(records));
            end
            
        end
        
        function prop = addProperty(obj, name, dataType, description, varargin)
            %ADDPROPERTY  Adds a property to a specific model
            %   PROP = ADDPROPERTY(OBJ, 'Name', 'Datatype', 'Description')
            %   add a single property to the model OBJ.
            %
            %   PROP = ADDPROPERTY(..., 'mult', true) allows users to add
            %   multiple values for the property in an instance.
            %
            %   PROP = ADDPROPERTY(..., 'enum', [...]) restricts the values
            %   of a property to the list specified in the array following
            %   the 'enum' parameter. This array can either be a cell array
            %   of strings when the 'dataType' is String, or a 1D array of
            %   numeric values if the 'dataType' is Double, or Long. You
            %   cannot use this attribute  for 'dataTypes' of Boolean, and
            %   Date.
            %
            %   PROP = ADDPROPERTY(..., 'required', true) makes the
            %   property a required property. Users cannot create records
            %   without specifying a value for this property.
            %
            %   PROP = ADDPROPERTY(..., 'type','modelName') specifies the
            %   type of model that is added as a linked property. This
            %   argument is required when the 'Datatype' argument is set to
            %   "model". A model with the provided name should exist in the
            %   dataset.
            %
            %   The 'Datatype' for each property has to be one of:
            %   ["Model", "String", "Boolean", "Date", "Double", or "Long"].
            %
            %   This function automatically sets the first property of a
            %   model to be the 'Concept Title'. This can be modified in
            %   the web-application.
            %
            %   For example:
            %       M = dataset.models(1)
            %       M.ADDPROPERTY('newProp', 'String', 'Description')
            %
            %       M.ADDPROPERTY('newProp', 'Number', 'Description',
            %       'mult',true,'enum', [ 1.1 2.4 3 4.2 5 ])
            %
            %       M.ADDPROPERTY('newProp', 'Decimal', 'Description',
            %       'enum', int64([ 1 2 3 4 5 ]))
            %
            %       M.ADDPROPERTY('newProp', 'Decimal', 'Description',
            %       'enum', int64([ 1 2 3 4 5 ]), 'required', true)
            %
            %       M.ADDPROPERTY('newProp', 'model', 'Description',
            %       'type', 'Patient')
            
            
            % Check inputs
            multInput = false;
            enumInput = [];
            requiredInput = false;
            modelType = '';
            if nargin < 4
                error('Incorrect number of input arguments.')
            elseif ~isempty(varargin) 
                assert(~mod(length(varargin),2), 'Incorrect number of input arguments.');
                for i=1:2:length(varargin)
                    switch varargin{i}
                        case 'mult'
                            multInput = varargin{i+1};
                        case 'enum'
                            enumInput = varargin{i+1};
                        case 'required'
                            requiredInput = varargin{i+1};
                        case 'type'
                            modelType = varargin{i+1};
                        otherwise
                            error('Incorrect input arguments.')
                    end
                end
            end
            
            assert(isa(description,'char') && isa(dataType,'char'), ...
                'When adding single property, input variables for name, datatype, and description need to be of type ''char''');

            % Check length enum/mult inputs
            assert(isempty(multInput) || length(multInput) == 1, ...
                'MULT input can only be of length 1 for a single property.');
            assert(isempty(enumInput) || any(size(enumInput)== 1), ...
                'Enum input has to be a vector');

            switch dataType
                case 'model'
                    allModelNames = {obj.dataset.models.name};
                    modelIdx = strcmp(modelType, allModelNames);
                    if ~any(modelIdx)
                        error('modelType is not a valid model name for this dataset');
                    end 
                    
                    modelId = obj.dataset.models(modelIdx).id_;
                    obj.session_.conceptsAPI.createLinkedProperty(...
                        obj.dataset.id_, obj.id_, name, modelId);
                    
                    obj.props = getProperties(obj);
                    
                    % find created property and return
                    propNames = {obj.props.displayName};
                    obj.nrProperties = length(obj.props);
                    prop = obj.props(strcmp(name, propNames));
                    
                otherwise
                    % Check type of enum/mult
                    assert(isempty(multInput) || isa(multInput, 'logical'), 'MULT input must be of type ''logical''');

                    % Get existing properties from webservice
                    existingProps = obj.session_.conceptsAPI.getProperties(obj.dataset.id_, obj.id_);

                    % Replace empty unit by empty string unit
                    for i=1: length(existingProps)
                        try
                            ff = fieldnames(existingProps(i).dataType.items);
                            if any(strcmp('unit',ff))
                                existingProps(i).dataType.items.unit = "";
                            end
                        catch
                        end
                    end

                    % Set concept title if no other properties yet.
                    setConceptTitle = true;
                    if ~isempty(existingProps)
                        setConceptTitle = false;
                    end

                    assert(any(strcmp(dataType,{'String' 'Boolean', 'Date', 'Double', 'Long'})), ...
                        'Datatype needs to be one of: [''Text'' ''Boolean'', ''Date'', ''Double'', ''Long''. ');

                    % Set complex datatype for multivalue and enum.
                    dataTypeObj = dataType;
                    if multInput || ~isempty(enumInput)
                        type = 'enum';
                        if multInput
                            type = 'array';
                        end

                        dataTypeObj = struct('type', type,'items', struct('type', dataType));

                        if ~isempty(enumInput)
                           dataTypeObj.items.enum = enumInput;

                           % Check if enum type matches dataType
                           assert(~any(strcmp(dataType, {'Date','Boolean'})), ...
                               "Enum parameter is not allowed for dataTypes ''Date'' or ''Boolean''.");

                           switch dataType
                               case 'String'
                                    assert(isa(enumInput, 'cell'), 'Enum must be cell array of Strings for datatype: String');
                                    assert(all(cellfun(@(x) ischar(x),enumInput)), ...
                                        'Enum must be cell array of Strings for datatype: String');
                               case 'Double'
                                    assert(isa(enumInput, 'double'), 'Enum must be 1xN numeric array of doubles for datatype: Double');
                               case 'Long'
                                    assert(isa(enumInput, 'int64'), 'Enum must be 1xN numeric array of int64 for datatype: Long');
                               otherwise
                                   error('Incorrect datatype.');
                           end
                        end
                    end

                    newProps = struct();
                    newProps.conceptTitle = setConceptTitle;
                    newProps.dataType = dataTypeObj;
                    newProps.default = requiredInput;
                    newProps.description = "";
                    newProps.displayName = name;
                    newProps.locked = false;
                    newProps.name = BFConceptsAPI.slugFromString(name);
                    newProps.value = "";
                    newProps.unit = "";

                    resp = obj.session_.conceptsAPI.updateModelProperties(...
                        obj.dataset.id_, obj.id_, existingProps, newProps);

                    if resp.StatusCode == matlab.net.http.StatusCode.BadRequest
                        error('There was an error creating the property, does another property with the same name already exist?');
                    end

                    obj.props = getProperties(obj);
                    obj.nrProperties = length(obj.props);

                    % find created property and return
                    propNames = {obj.props.name};
                    prop = obj.props(strcmp(newProps.name, propNames));
            end
        end
        
        function resp = getRelationships(obj)                           
            resp = obj.session_.conceptsAPI.getRelationships(obj.dataset.id_, obj.id_);
        end
        
        function relationship = createRelationship(obj, targetModel, name)
            % CREATERELATIONSHIP  Creates a relationship between models
            %   REL = CREATERELATIONSHIP(OBJ, TARGET, 'name') creates a
            %   relationship between the current model and the TARGETMODEL
            %   with a specified 'name'. 
            %
            %   A relationship needs to be created in order to link records
            %   to eachother. Relationships between records always adhere
            %   to one of the defined relationships that are created for
            %   a model.
            %
            %   For example:
            %       MODEL1 = DS.CREATEMODEL('model1', 'description 1');
            %       MODEL2 = DS.CREATEMODEL('model2', 'description 2');
            %       REL = MODEL1.CREATERELATIONSHIP(MODEL2, 'contains');
            %
            %       Once a relationship is created, you can use the
            %       relationship to link between records of the respective
            %       models.
            %       
            %       model1Record.link(model2record, REL);
            %
            %   See also:
            %       BFRECORD.LINK
            
            response = obj.session_.conceptsAPI.createRelationship(...
                obj.dataset.id_, obj.id_, targetModel.id_, name, '');
            
            relationship = BFRelationship.createFromResponse(response, obj.session_, obj.dataset);
            obj.relationshipChecked = false;
                        
        end
    end
    
    methods (Access = protected)                                        
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: methods(%s.empty)">Methods</a>',obj.id_,class(obj));
            else
                s = '';
            end
        end
        
        function props = getProperties(obj)
            
            % Get standard properties
            resp = obj.session_.conceptsAPI.getProperties(obj.dataset.id_, obj.id_);
            props =  BFModelProperty.createFromResponse(resp, obj.session_);
            
            % Get linked properties
            resp = obj.session_.conceptsAPI.getLinkedProperties(obj.dataset.id_, obj.id_);
            linkedProps = BFLinkedModelProperty.createFromResponse(resp, obj.session_);
            props = [props linkedProps];
            
        end
    end
    
    methods (Static)
        function out = createFromResponse(resp, session, dataset)       
          %CREATEFROMRESPONSE  Create object from server response 
          
          out = BFModel(session, dataset, resp.id, resp.name, ...
              resp.displayName, resp.description, resp.locked);
          out.nrRecords = resp.count;
          out.nrProperties = resp.propertyCount;
          
          out.setDates(resp.createdAt, resp.createdBy, resp.updatedAt, resp.updatedBy); 
          
          out.props = out.getProperties();

        end
    end
end

