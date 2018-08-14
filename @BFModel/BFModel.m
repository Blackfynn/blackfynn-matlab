classdef BFModel < BFBaseModelNode
    %BFMODEL A Metadata model
    %   Detailed explanation goes here
    
    properties
        nrRecords = 0           % Number of records for this model
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
        
        function records = getall(obj, varargin)
            %GETALL Returns records of the given model
            %   RECORDS = GETALL(OBJ) returns the first 100 records for the
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
            endPoint = sprintf('%s/datasets/%s/concepts/%s/instances',...
                obj.session.concepts_host, obj.datasetId,obj.id);
            
            request = obj.session.request;
            resp = request.get(endPoint, params);
            records = obj.handleGetRecords(resp);
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
                records(i) = BFRecord.createFromResponse(resp(i), obj.session, obj.id);
            end
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
        end
    end
end

