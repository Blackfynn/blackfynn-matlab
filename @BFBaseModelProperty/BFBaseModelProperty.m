classdef BFBaseModelProperty < BFBaseNode & matlab.mixin.Heterogeneous
    % BFBASEMODELPROPERTY Base representation for model properties
    %   This class captures attributes for properties of models in the
    %   Blackfynn platform. It is extended by the BFMODELPROPERTY class.

    properties    
        name            % String with name of property
        displayName     % String with pretty name of property
        index           % Index of the property in the class
        locked          % Boolean indicating property is locked
        default         % Boolean indicating property is default
        conceptTitle    % Boolean indicating property is concept title
        createdAt       % String with property creation date
        updatedAt       % String with property update data
        required        % Boolean indicating property is required
    end
    
    methods
        function obj = BFBaseModelProperty(session, id, index, locked,...
                default, conceptTitle, createdAt, updatedAt, required)
            % BFBASEMODELPROPERTY Construct an instance of this class
            %   OBJ = BFBASEMODELPROPERTY(SESSION, 'id', INDEX, LOCKED,
            %   DEFAULT, CONCEPTTITLE, 'createdAt', 'updatedAt', REQUIRED)
            %   creates an instance of the BFBASEMODELPROPERTY class. 
            
            narginchk(9,9);
            obj = obj@BFBaseNode(session, id);
            
            if nargin
                obj.index = index;
                obj.locked = logical(locked);
                obj.default = logical(default);
                obj.conceptTitle = logical(conceptTitle);
                obj.createdAt = createdAt;
                obj.updatedAt = updatedAt;
                obj.required = logical(required);
            end
        end
    end    
end

