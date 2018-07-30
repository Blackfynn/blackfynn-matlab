classdef BFDataset < BFBaseCollection
    %BFDATASET  Representation of a Dataset objet on the Blackfynn platform
    
    properties
        description
    end
    
    methods (Sealed = true)
        
        function obj = BFDataset(varargin)
            % Args: Empty, or [session, id, name, type]
            
            obj = obj@BFBaseCollection(varargin{:} );
        end
        
        function out = update(obj)
            %UPDATE updates dataset on the platform.
            id = obj.id;
            uri = sprintf('%s/%s/%s', obj.session.host, 'datasets', id);
            params = struct(...
                'name', obj.name,...
                'description', obj.description,...
                'properties', []);
            obj.session.request.put(uri, params);
            out=obj;
        end
        
        function out = models(obj)
            % MODELS Returns models for the dataset.
            %   MODELS = MODELS(OBJ) returns an array of BFMODELS that are
            %   defined for the dataset.
            %
            %   Example:
            %
            %       BF = Blackfynn()
            %       MODELS = BF.MODELS()
            
            uri = 'concepts';
            params = {};
            endPoint = sprintf('%s/datasets/%s/%s',obj.session.concepts_host, obj.id, uri);
            
            request = obj.session.request;
            resp = request.get(endPoint, params);
            out = obj.handleGetModels(resp);

        end
    end
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s',obj.session.web_host,obj.session.org,obj.id);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,url,class(obj));
            else
                s = '';
            end
        end
        
        function models = handleGetModels(obj,resp)
            
            models = BFModel.empty(length(resp),0);
            for i=1: length(resp)
                models(i) = BFModel.createFromResponse(resp(i), obj.session, obj.id);
            end
        end
    end
    methods (Static, Hidden)
        function out = createFromResponse(resp, session)
            % CREATEFROMRESPONSE creates a BF dataset object from a
            % response.
            %
            content = resp.content;
            out = BFDataset(session, content.id, content.name, content.packageType);
            
            if isfield(content, 'description')
                out.description = content.description;
            end

        end
    end
    
end