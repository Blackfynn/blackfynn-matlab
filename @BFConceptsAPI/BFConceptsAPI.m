classdef BFConceptsAPI
    %BFCONCEPTSAPI Summary of this class goes here
    %   Detailed explanation goes here
    
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
        
        function models = getModels(obj, datasetId)
            
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts',obj.host, datasetId);
            
            request = obj.session.request;
            response = request.get(endPoint, params);
            
            models = BFModel.empty(length(response),0);
            for i=1: length(response)
                models(i) = BFModel.createFromResponse(response(i), obj.session, datasetId);
            end
        end
        
        function records = getRecords(obj, datasetId, modelId, varargin)

            params = {};
            if nargin >1
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances', ...
                obj.host, datasetId, modelId);
            
            response = obj.session.request.get(endPoint, params);
            
            records = BFRecord.empty(length(response),0);
            for i=1: length(response)
                records(i) = BFRecord.createFromResponse(response(i), ...
                    obj.session, modelId, datasetId);
            end
        end
        
        function records = createRecords(obj, datasetId, modelId, data)
            
            batch_array = {};
            for i=1: length(data)
                curItem = data(i);
                fields = fieldnames(curItem);
                
                rec_array = struct('name',{},'value',{});
                for j=1: length(fields)
                    rec_array(j) = struct('name',fields{j}, 'value', curItem.(fields{j}));
                end
                batch_array{i} = sprintf('{"values": %s }',jsonencode(rec_array)); %#ok<AGROW>
            end
                    
            message = sprintf('%s,',batch_array{:});
            message = ['[' message(1:end-1) ']'];

            % Create object from response
            endpoint = sprintf('%s/datasets/%s/concepts/%s/instances/batch', obj.host, datasetId, modelId);
            response = obj.session.request.post(endpoint, message);
            
            records = BFRecord.empty(length(response),0);
            if (isa(response,'struct'))
                % All records could be created
                for i=1: length(response)
                    records(i) = BFRecord.createFromResponse(response(i), obj.session, modelId, datasetId);
                end
            else
                % Some records could not be created
                for i=1: length(response)
                    if (isa(response{i},'struct'))
                        records(i) = BFRecord.createFromResponse(response{i}, obj.session, modelId, datasetId);
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
        
    end
end
