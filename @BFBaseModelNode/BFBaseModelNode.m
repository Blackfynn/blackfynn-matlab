classdef BFBaseModelNode < BFBaseNode
    %BFBASEMODELNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        displayName     % Identifying property
        description     % Description of the model
        locked          % Is model locked?
    end
    
    properties( Hidden)
        datasetId       % Id of the dataset
        type            % Type of the model
        createDate       % Creation data
        updateDate       % Updated date
    end
    
    methods
        function obj = BFBaseModelNode(varargin)
            %BFBASEMODELNODE Construct an instance of this class
            %   args = [session, id, name, display_name,
            %           description, locked, created_at, updated_at]
            
            obj = obj@BFBaseNode(varargin{:});
            
            if nargin
                obj.type = varargin{3};
                obj.displayName = varargin{4};
                obj.description = varargin{5};
                obj.locked = varargin{6};
                obj.createDate = varargin{7};
                obj.updateDate = varargin{8};
            end
        end
        
    end
end

