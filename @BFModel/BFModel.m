classdef BFModel < BFBaseModelNode
    %BFMODEL A Metadata model
    %   Detailed explanation goes here
    
    properties
        nrRecords = 0           % Number of records for this model
        props = []              % Array of property details
    end
    
    properties (Hidden)
        nrProperties = 0        % Number of properties in the model
    end

    
    methods
        function obj = BFModel(obj, varargin)
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
            
            params = {};
            if nargin >1
                params = {'limit',varargin{1}, 'offset',varargin{2}};
            end
            
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances',...
                obj.session.concepts_host, obj.datasetId,obj.id);
            
            request = obj.session.request;
            resp = request.get(endPoint, params);
            records = obj.handleGetRecords(resp);
        end
        function out = createRecords(obj, values)
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
                        
            % Create using API
            batch_array = {};
            for i=1: length(values)
                curItem = values(i);
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
            uri = sprintf('%s/datasets/%s/concepts/%s/instances/batch', obj.session.concepts_host, obj.datasetId, obj.id);
            response = obj.session.request.post(uri, message);
            out = BFRecord.empty(length(response),0);
            for i=1: length(response)
                out(i) = BFRecord.createFromResponse(response(i), obj.session, obj.id, obj.datasetId);
            end

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
            params = {};
            endPoint = sprintf('%s/datasets/%s/concepts/%s/properties',...
                obj.session.concepts_host, obj.datasetId,obj.id);
            
            request = obj.session.request;
            props = request.get(endPoint, params);
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

