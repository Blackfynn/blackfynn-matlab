classdef BFConceptsAPI
    %BFCONCEPTSAPI Class interacting with the Blackfynn API
    %   The BFCONCEPTSAPI class implements all methods that are available
    %   in the concepts API. 
    
    properties
        session
        host = 'https://concepts.blackfynn.io';
        name = 'concepts';
    end
    
    methods

        function obj = BFConceptsAPI(session, varargin)
            %BFCONCEPTSAPI Construct an instance of this class
            %   Detailed explanation goes here
            
            narginchk(1,2);
            obj.session = session;
            
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
            request = obj.session.request;

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
            request = obj.session.request;
            response = request.put(endPoint, params2); 
        end
            
        function response = getModels(obj, datasetId)
            
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts',obj.host, datasetId);
            
            request = obj.session.request;
            response = request.get(endPoint, params);            
        end
        
        function response = getRecords(obj, datasetId, modelId, varargin)

            params = {};
            if nargin > 3
                assert(length(varargin) == 2, 'Incorrect number of input arguments');
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances', ...
                obj.host, datasetId, modelId);
            
            response = obj.session.request.get(endPoint, params);
            
        end
        
        function records = createRecords(obj, dataset, modelId, data)
            
            batch_array = {};
            for i=1: length(data)
                curItem = data(i);
                fields = fieldnames(curItem);
                
                rec_array = struct('name',{},'value',{});
                for j=1: length(fields)
                    item = struct();
                    item.name = fields{j};
                    item.value = curItem.(fields{j});
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
            endpoint = sprintf('%s/datasets/%s/concepts/%s/instances/batch', obj.host, dataset.id, modelId);
            response = obj.session.request.post(endpoint, message);
            
            records = BFRecord.empty(length(response),0);
            if (isa(response,'struct'))
                % All records could be created
                for i=1: length(response)
                    records(i) = BFRecord.createFromResponse(response(i), obj.session, modelId, dataset);
                end
            else
                % Some records could not be created
                for i=1: length(response)
                    if (isa(response{i},'struct'))
                        records(i) = BFRecord.createFromResponse(response{i}, obj.session, modelId, dataset);
                    else
                        fprintf(2, 'Unable to create record from index: %i\n', i);
                    end
                end
            end
            
        end
        
        function props = getProperties(obj, datasetId, modelId)
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/properties',...
                obj.host, datasetId, modelId);
            
            request = obj.session.request;
            props = request.get(endPoint, params);
        end
        
        function success = deleteRecords(obj, datasetId, modelId, recordIds)
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances',...
                obj.host, datasetId, modelId);
            
            request = obj.session.request;
            response = request.delete(endPoint, recordIds);
            
            if response.StatusCode == 'OK'
                success =  response.Body.Data.success;
            else
                error('Unable to perform request.')
            end
            
        end
        
        function response = getRelationCountsForRecord(obj, datasetId, modelId, recordId)
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/relationCounts', ...
                obj.host, datasetId, modelId, recordId);
            
            response = obj.session.request.get(endPoint, params);
        end
        
        function response = getRelated(obj, datasetId, modelId, recordId, targetModelId, varargin)
            params = {};
            if nargin > 5
                assert(length(varargin) == 2, 'Incorrect number of input arguments');
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances/%s/relations/%s', ...
                obj.host, datasetId, modelId, recordId, targetModelId);
            
            response = obj.session.request.get(endPoint, params);
            
        end
        
        function response = createRelationship(obj, datasetId, sourceModelId, targetModelId, relationshipName, description)
            endPoint = sprintf('%s/datasets/%s/relationships',obj.host, datasetId);
            
            message = struct(...
                'name', relationshipName, ...
                'displayName', relationshipName, ...
                'description', description, ...
                'schema', {struct( ...
                    'name', relationshipName, ...
                    'displayName', 'string', ...
                    'dataType', {}, ...
                    'locked', true, ...
                    'default', true, ...
                    'conceptTitle', true, ...
                    'description', 'string', ...
                    'required', true, ...
                    'defaultValue', ' '...
                    )}, ...
                'from', sourceModelId, ...
                'to', targetModelId); 
            
            params = jsonencode(message);
            request = obj.session.request;
            response = request.post(endPoint, params);  
        end
        
        function response = getRelationships(obj, datasetId, modelId)
            params = {};
            if nargin > 2
                params = {'from', modelId};
            end
            
            endPoint = sprintf('%s/datasets/%s/relationships', ...
                obj.host, datasetId );
            
            response = obj.session.request.get(endPoint, params);
            
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

