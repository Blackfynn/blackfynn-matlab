classdef (Sealed) BFCollection < BFBaseCollection
    % BFCOLLECTION  An object that contains other collections or
    % packages.
    %
    properties
        datasetId
        state
    end
    
    methods (Sealed = true)
        function obj = BFCollection(varargin)
            % BFCOLLECTION Base class used for ``BFCollection`` objects
            %
            % Args:
            %       ID (str): collection's ID
            %       name (str): name of the collection.
            %       type (str): ``BFDataset``
            %
            % Returns:
            %           ``BFCollection``: Collection object
            %
            obj = obj@BFBaseCollection(varargin{:});
        end
    end
    
    methods (Static, Hidden)
        function out = createFromResponse(resp, session)
            % CREATEFROMRESPONSE creates a BF collection object from a
            % response.
            %
            content = resp.content;
            if ~isfield(resp, 'children')
                resp = BFCollection.get_collection(resp.content.id,session);
                content = resp.content;
            end
            
            out = BFCollection(session, content.id, content.name,...
                content.packageType);
            out.datasetId = content.datasetId;
            out.state = content.state;
            out.items_ = resp.children;
        end
        
        function out = get_collection(id, session)
            % GET_COLLECTION retrieves a collection object from the
            % platform.
            %
            uri = sprintf('%s%s%s', session.host,'packages/', id);
            params = {'includeAncestors', 'false',...
                'session', session.request.options.HeaderFields{2}};
            out = session.request.get(uri, params);
        end
    end
end