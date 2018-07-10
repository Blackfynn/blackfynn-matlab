classdef BFDataset < BFBaseCollection
    %BFDATASET  Representation of a Dataset objet on the Blackfynn platform
    
    properties
        description
    end
    
    methods (Sealed = true)
        
        function obj = BFDataset(varargin)
            % BFDATASET Base class used for ``BFDataset`` objects
            %
            % Args:
            %       ID (str): dataset's ID
            %       name (str): name of the dataset.
            %       type (str): ``BFDataset``
            %
            % Returns:
            %           ``BFDataset``: Dataset object
            %
            obj = obj@BFBaseCollection(varargin{:} );
        end
        
        function out = update(obj)
            %UPDATE updates object on the platform.
            %
            id = obj.get_id;
            uri = sprintf('%s%s%s', obj.session.host, 'datasets/', id);
            params = struct(...
                'name', obj.name,...
                'description', obj.description,...
                'properties', []);
            obj.session.request.put(uri, params);
            out=obj;
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
        
    % end of static methods
    end
    
end