classdef BFBaseModelProperty < BFBaseNode
    %BFBASEMODELPROPERTY Summary of this class goes here
    
    properties        
        index
        locked
        default
        conceptTitle
        createdAt
        updatedAt
        required
    end
    
    methods
        function obj = BFBaseModelProperty(varargin)
            %BFBASEMODELPROPERTY Construct an instance of this class
            % Args: Empty, or [session, id, index, locked, default, conceptTitle, createdAt, updatedAt, required]
            obj = obj@BFBaseNode(varargin{:});
            
            obj.index = varargin{3};
            obj.locked = logical(varargin{4});
            obj.default = logical(varargin{5});
            obj.conceptTitle = logical(varargin{6});
            obj.createdAt = varargin{7};
            obj.updatedAt = varargin{8};
            obj.required = logical(varargin{9});
            
        end
    end
end

