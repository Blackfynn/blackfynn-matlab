classdef BFBaseModelNode < BFBaseNode
    %BFBASEMODELNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name            % Identifying property
        description     % Description of the model
        locked          % Is model locked?
    end
    
    properties( Hidden)
        datasetId       % Id of the dataset
        type            % Type of the model
        createDate      % Creation data
        updateDate      % Updated date
    end
    
    methods
        function obj = BFBaseModelNode(session, id, type, display_name,...
                      description, locked, created_at, updated_at)
            % BFBASEMODELNODE Constructs an instance of this class
            %     OBJ = BFBASEMODELNODE(SESSION, 'id', 'name',
            %     'displayName','description', LOCKED, 'createdAt',
            %     'updatedAt') creates an object of class BFMODEL.
            
            obj = obj@BFBaseNode(session, id);
            
            if nargin
                obj.type = type;
                obj.name = display_name;
                obj.description = description;
                obj.locked = locked;
                obj.createDate = created_at;
                obj.updateDate = updated_at;
            end
        end
        
    end
end

