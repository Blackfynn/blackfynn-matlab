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
        
    end
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/files',obj.session.web_host,obj.session.org, obj.id);
                s = sprintf('  <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',url,class(obj));
            else
                s = '';
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