classdef BFBaseSchemaNode < BFBaseNode
    %BFBASESCHEMANODE Base class for models and relationships
    
    properties
        name            % Identifying property
        description     % Description of the model
    end
    
    properties( Hidden)
        displayName     % Pretty name that is used in the Web Application
        dataset         % Associated dataset
        createdAt       % Creation data
        updatedAt       % Updated date
        createdBy       % User ID of person who created the schema node
        updatedBy       % User ID of person who updated the schema node
    end
    
    methods
        function obj = BFBaseSchemaNode(session, dataset, id, name, display_name, description)
            % BFBASESCHEMANODE Constructs an instance of this class
            
            obj = obj@BFBaseNode(session, id);
            obj.dataset = dataset;
            obj.name = name;
            obj.name = display_name;
            obj.description = description;
        end
        
    end
    
    methods (Access = protected)
        function obj = setDates(obj, createdAt, createdBy, updatedAt, updatedBy)
            % SETDATES sets the create/update dates for the object
            %   OBJ = SETDATES(OBJ, 'createdAt', 'createdBy', 'updatedAt',
            %   'updatedBy') sets the creation and update information for
            %   objects of this class.
            
            obj.createdAt = createdAt;
            obj.updatedAt = updatedAt;
            obj.createdBy = createdBy;
            obj.updatedBy = updatedBy;
        end
        
    end
end
