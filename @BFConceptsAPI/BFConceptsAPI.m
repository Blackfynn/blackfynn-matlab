classdef BFConceptsAPI
    %BFCONCEPTSAPI Class interacting with the Blackfynn API
    %   The BFCONCEPTSAPI class implements all methods that are available
    %   in the concepts API. 
    
    properties
        session_
        host = 'https://concepts.blackfynn.io';
        name = 'concepts';
    end
    
    methods

        function obj = BFConceptsAPI(session, varargin)
            %BFCONCEPTSAPI Construct an instance of this class
            %   Detailed explanation goes here
            
            narginchk(1,2);
            obj.session_ = session;
            
            if nargin == 2
                obj.host = varargin{1};
            end
            
            % Turn off warnings about DELETE method having a body in the
            % request.
            warning('off','MATLAB:http:BodyUnexpectedFor');
            
        end
        
        function response = createModel(obj, datasetId, name, description)
            %CREATEMODEL  Creates a model in the dataset
            
            name2 = strip(name);
            slug = BFConceptsAPI.slugFromString(name2);
            
            message = struct( ...
            'name', slug, ... 
            'displayName', name2, ...
            'description', description, ...
            'locked', false);
                
            endPoint = sprintf('%s/datasets/%s/concepts',obj.host,datasetId);
            params = jsonencode(message);
            request = obj.session_.request;

            try
                response = request.post(endPoint, params);  
            catch ME
                if (strcmp(ME.identifier,'MATLAB:webservices:HTTP409StatusCodeError'))
                    fprintf(2, 'Unable to create model because a model with this name already exists.\n');
                end
                throwAsCaller(ME);
            end   
        end
        
        function response = updateModelProperties(obj, datasetId, modelId, existingProps, newProps)
            % Propinfo needs to be a struct, or array of structs with the
            % following structure:
            %       conceptTitle: true
            %       dataType: "String"
            %       default: true
            %       description: "description"
            %       displayName: "name"
            %       locked: "false"
            %       name: "name"
            %       value: ""
            
            message = cell.empty(length(existingProps)+1,0);
            idx = 1;
            for i=1:length(existingProps)
                message{idx} = existingProps(i);
                idx = idx+1;
            end
            for i=1:length(newProps)
                message{idx} = newProps(i);
                idx = idx +1;
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/properties',obj.host, datasetId, modelId);
            params = (jsonencode(message));
            params2 = uint8(params);
            request = obj.session_.request;
            response = request.put(endPoint, params2); 
        end
        
        function response = getLinkedProperties(obj, datasetId, modelId)
            
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/linked', obj.host, datasetId, modelId);
            
            request = obj.session_.request;
            response = request.get(endPoint, params);      
        end
        
        function response = createLinkedProperty(obj, datasetId, modelId, propName, toModelId)
            
            name2 = strip(propName);
            slug = BFConceptsAPI.slugFromString(name2);
            
            message = struct( ...
            'name', slug, ... 
            'displayName', name2, ...
            'to', toModelId, ...
            'position', 0);
                
            endPoint = sprintf('%s/datasets/%s/concepts/%s/linked',obj.host,datasetId, modelId);
            params = jsonencode(message);
            request = obj.session_.request;

            try
                response = request.post(endPoint, params);  
            catch ME
                if (strcmp(ME.identifier,'MATLAB:webservices:HTTP409StatusCodeError'))
                    fprintf(2, 'Unable to create linked property.\n');
                end
                throwAsCaller(ME);
            end   
            
        end
        
        function response = getModels(obj, datasetId)
            
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts',obj.host, datasetId);
            
            request = obj.session_.request;
            response = request.get(endPoint, params);            
        end
        
        function response = getRecordInstance(obj, datasetId, modelId, recordId)
            
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s', ...
                obj.host, datasetId, modelId, recordId);
            
            response = obj.session_.request.get(endPoint, params);
        end
        
        function response = getRecords(obj, datasetId, modelId, varargin)

            params = {};
            if nargin > 3
                assert(length(varargin) == 2, 'Incorrect number of input arguments');
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances', ...
                obj.host, datasetId, modelId);
            
            response = obj.session_.request.get(endPoint, params);
            
        end
        
        function response = getLinkedPropertiesForInstance(obj, datasetId, modelId, recordId)
            
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/linked', ...
                obj.host, datasetId, modelId, recordId);
            
            request = obj.session_.request;
            response = request.get(endPoint, params);   
            
        end
        
        function response = setLinkedPropertyForRecord(obj, datasetId, modelId, recordId, propertyName, propertyId, toRecordId)
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/linked', ...
                    obj.host, datasetId, modelId, recordId);

            params = struct(...
                'name', propertyName,...
                'displayName', propertyName, ...
                'schemaLinkedPropertyId', propertyId, ...
                'to', toRecordId);

            request = obj.session_.request;
            response = request.post(endPoint, params); 
        end
        
        function response = removeLinkedPropertyForRecord(obj, datasetId, modelId, recordId, linkId)
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/linked/%s',...
                obj.host, datasetId, modelId, recordId, linkId);
            
            request = obj.session_.request;
            response = request.delete(endPoint,{});
            
            if response.StatusCode ~= 'OK'
                error('Unable to perform request.')
            end
        end
        
        function records = createRecords(obj, dataset, model, data)
            
            propNames = {model.props.name};
            
            batch_array = {};
            for i=1: length(data)
                curItem = data(i);
                fields = fieldnames(curItem);
                
                rec_array = struct('name',{},'value',{});
                for j=1: length(fields)
                    item = struct();
                    item.name = lower(fields{j});
                    item.value = curItem.(fields{j});
                    
                    % Validate value
                    curProp = model.props(strcmpi(item.name, propNames));
                    switch curProp.dataType
                        case 'String'
                            if isempty(item.value)
                                item.value = '';
                            end
                        case 'Date'
                            if isnumeric(item.value)
                                item.value = datestr(item.value, ...
                                    'YYYY-MM-DDThh:mm:ss.000+00:00');
                            end
                        case 'Model'
                        case 'Double'
                            assert(isnumeric(item.value), sprintf('Incorrect dataType for property: %s',item.name));
                            if isempty(item.value)
                                item.value = NaN;
                            end
                        case 'Long'
                            assert(mod(item.value,1)==0, sprintf('Incorrect dataType for property: %s',item.name));
                            if isempty(item.value)
                                item.value = NaN;
                            end
                        otherwise
                            
                    end
                    
                    
                    rec_array(j) = item;
                end
                jsonArray = jsonencode(rec_array);
                if length(fields) == 1
                    jsonArray = ['[' jsonArray ']']; %#ok<AGROW>
                end
                
                batch_array{i} = sprintf('{"values": %s }',jsonArray); %#ok<AGROW>
            end
                    
            message = sprintf('%s,',batch_array{:});
            message = ['[' message(1:end-1) ']'];

            % Create object from response
            endpoint = sprintf('%s/datasets/%s/concepts/%s/instances/batch', obj.host, dataset.id_, model.id_);
            response = obj.session_.request.post(endpoint, message);
            
            records = BFRecord.empty(length(response),0);
            if (isa(response,'struct'))
                % All records could be created
                for i=1: length(response)
                    records(i) = BFRecord.createFromResponse(response(i), obj.session_, model, dataset);
                end
            else
                % Some records could not be created
                for i=1: length(response)
                    if (isa(response{i},'struct'))
                        records(i) = BFRecord.createFromResponse(response{i}, obj.session_, model, dataset);
                    else
                        fprintf(2, 'Unable to create record from index: %i\n', i);
                    end
                end
            end
            
        end
        
        function response = updateRecord(obj, record)
            
            % Update standard properties
            allProps = record.model_.props;            
            content = {};
            for i=1:length(allProps)
                if isa(allProps(i), 'BFModelProperty')
                    updatedValue = record.(allProps(i).name);
                    
                    % Parse empty-cases
                    switch allProps(i).dataType
                        case 'String'
                            if isempty(updatedValue)
                                updatedValue = '';
                            end
                    end
                    
                    content{i} = struct('name', allProps(i).name, 'value',...
                        updatedValue); %#ok<AGROW>
                end
            end
            params = struct('values',[]);
            params.values = content;

            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s', ...
                obj.host, record.dataset_.id_, record.model_.id_, record.id_);
            
            request = obj.session_.request;
            response = request.put(endPoint, params);          
            
            % Update linked properties
            for i=1: length(record.updatedLinkedProps_)
                prop = allProps(strcmp(record.updatedLinkedProps_{i}, {allProps.name}));
                propRec = record.(sprintf('%s_', prop.name));
                
                % Delete existing link if exist
                if ~isempty(propRec{4})
                    obj.removeLinkedPropertyForRecord(record.dataset_.id_, ...
                        record.model_.id_, record.id_, propRec{4});
                end
                
                % Add new link
                response = obj.setLinkedPropertyForRecord(record.dataset_.id_, ...
                    record.model_.id_, record.id_, prop.name, prop.id_, propRec{1}.id_);
                
                record.(sprintf('%s_', prop.name)){4} = response.id;
            end

            % Set updated to false
            record.updatedLinkedProps_ = {};
            record.updated_ = false;

        end
        
        function props = getProperties(obj, datasetId, modelId)
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/properties',...
                obj.host, datasetId, modelId);
            
            request = obj.session_.request;
            props = request.get(endPoint, params);
        end
        
        function success = deleteRecords(obj, datasetId, modelId, recordIds)
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances',...
                obj.host, datasetId, modelId);
            
            request = obj.session_.request;
            response = request.delete(endPoint, recordIds);
            
            if response.StatusCode == 'OK'
                success = true;
            else
                error('Unable to perform request.')
            end
            
        end
                
        function response = getRelationCountsForRecord(obj, datasetId, modelId, recordId)
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/relationCounts', ...
                obj.host, datasetId, modelId, recordId);
            
            response = obj.session_.request.get(endPoint, params);
        end
        
        function response = getRelated(obj, datasetId, modelId, recordId, targetModelId, varargin)
            params = {};
            if nargin > 5
                assert(length(varargin) == 2, 'Incorrect number of input arguments');
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/relations/%s', ...
                obj.host, datasetId, modelId, recordId, targetModelId);
            
            response = obj.session_.request.get(endPoint, params);
            
        end
        
        function response = createRelationship(obj, datasetId, sourceModelId, targetModelId, relationshipName, description)
            
            endPoint = sprintf('%s/datasets/%s/relationships',obj.host, datasetId);
            uuid = java.util.UUID.randomUUID;
            
            message = struct(...
                'name', sprintf('%s_%s', relationshipName, uuid), ...
                'displayName', relationshipName, ...
                'description', description, ...
                'schema', {[]}, ...
                'from', sourceModelId, ...
                'to', targetModelId); 
            
            params = jsonencode(message);
            request = obj.session_.request;
            response = request.post(endPoint, params);  
        end
        
        function response = getRelationships(obj, datasetId, modelId)
            % GETRELATIONSHIPS  Return relationships for dataset
            %   RESPONSE = GETRELATIONSHIPS(OBJ, 'datasetId') returns all
            %   defined relationships for the dataset.
            %
            %   RESPONSE = GETRELATIONSHIPS(OBJ, 'datasetId', 'modelId')
            %   only returns relationships for the provided model.
            
            params = {};
            if nargin > 2
                params = {'from', modelId};
            end
            
            endPoint = sprintf('%s/datasets/%s/relationships', ...
                obj.host, datasetId );
            
            response = obj.session_.request.get(endPoint, params);
            
        end
        
        function response = getFiles(obj, datasetId, modelId, recordId, varargin)
            
            params = {};
            if nargin > 4
                assert(length(varargin) == 2, 'Incorrect number of input arguments');
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/files', ...
                obj.host, datasetId, modelId, recordId);
            
            response = obj.session_.request.get(endPoint, params);
            
        end
        
        function response = link(obj, datasetId, relationshipId, fromId, toIds)
            % LINK Creates relationships between records
            
            endPoint = sprintf('%s/datasets/%s/relationships/%s/instances/batch',...
                obj.host, datasetId, relationshipId);
            
            
            batchArray = {};
            for i = 1: length(toIds)
                item = struct( ...
                    'from', fromId, ...
                    'to', toIds(i), ...
                    'values', []);
                batchArray{i} = jsonencode(item); %#ok<AGROW>
                
 
            end
            
            message = sprintf('%s,', batchArray{:});
            message = ['[' message(1:end-1) ']'];
           
            
            params = message;
            request = obj.session_.request;
            response = request.post(endPoint, params);         
        end
        
        function response = linkFile(obj, datasetId, recordIds, fileId)
            %LINKFILE Links file to one or more records
            
            
            % Check if BelongsTo Relationship already exists
            endPoint = sprintf('%s/datasets/%s/relationships', ...
                obj.host, datasetId);
            
            request = obj.session_.request;
            response = request.get(endPoint, {}); 
            
            % If BelongsTo does not exist, create relationship
            if isempty(response) || ~any(strcmp({response.name}, 'belongs_to')) 
                endPoint = sprintf('%s/datasets/%s/relationships', ...
                    obj.host, datasetId);

                params = struct(...
                    'name', 'belongs_to',...
                    'displayName', 'Belongs To', ...
                    'description', '', ...
                    'schema', []);

                request.post(endPoint, params); 
            end
            
            % Add File
            endPoint = sprintf('%s/datasets/%s/proxy/%s/instances', ...
                obj.host, datasetId, 'package');
            
            targets = {};
            for i = 1: length(recordIds)
                targets{i} = struct(...
                    'direction', 'FromTarget',...
                    'linkTarget', struct(...
                        'ConceptInstance',struct('id', recordIds(i))),...
                    'relationshipType', 'belongs_to',...
                    'relationshipData', []); %#ok<AGROW>
            end            
            params = struct(...
                'externalId', fileId);
            
            params.targets = targets;
            
            response = request.post(endPoint, params); 
            
        end
        
    end
    
    methods(Static)
        function str = slugFromString(input)
            % lowercase and strip of whitespace
            str1 = strip(lower(input));
            
            % replace characters
            str = regexprep(str1,'[\s\\^/:;.]','_');
            
            % remove duplicates
            str = regexprep(str,'_+','_');
        end
        
    end
end

