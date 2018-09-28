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
            
            content = resp.content;
            out = BFCollection(session, content.id, content.name,...
                content.packageType);
            out.datasetId = content.datasetId;
            out.state = content.state;
        end
        
    end
end