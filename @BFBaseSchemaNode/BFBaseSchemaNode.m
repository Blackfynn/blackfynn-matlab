classdef BFBaseSchemaNode < BFBaseNode
    %BFBASESCHEMANODE Base class for models and relationships
    
    properties
        name            % Identifying property
        description     % Description of the model
    end
    
    properties( Hidden)
        displayName     % 
        dataset         %  dataset
        createdAt       % Creation data
        updatedAt       % Updated date
        createdBy
        updatedBy
    end
    
    methods
        function obj = BFBaseSchemaNode(session, id, name, display_name, description)
            % BFBASESCHEMANODE Constructs an instance of this class
            
            obj = obj@BFBaseNode(session, id);
            obj.name = name;
            obj.name = display_name;
            obj.description = description;
        end
        
    end
    
    methods (Access = protected)
        function obj = setDates(obj, createdAt, createdBy, updatedAt, updatedBy)
            obj.createdAt = createdAt;
            obj.updatedAt = updatedAt;
            obj.createdBy = createdBy;
            obj.updatedBy = updatedBy;
        end
        
    end
end
