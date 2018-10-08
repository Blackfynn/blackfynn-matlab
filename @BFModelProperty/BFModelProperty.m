classdef BFModelProperty < BFBaseModelProperty
    %BFMODELPROPERTY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        displayName
        dataType
        description
        defaultValue
    end
    
    methods
        function obj = BFModelProperty(varargin)
            %BFMODELPROPERTY Construct an instance of this class
            % Args: Empty, or [session, id, index, locked, default,
            % conceptTitle, createdAt, updatedAt, required, name,
            % displayName, dataType, description, defaultValue]

            obj = obj@BFBaseModelProperty(varargin{:});
            obj.name = varargin{10};
            obj.displayName = varargin{11};
            obj.dataType = varargin{12};
            obj.description = varargin{13};
            obj.defaultValue = varargin{14};
        end
    end
    
    methods (Static)
        function out = createFromResponse(resp, session)
          %CREATEFROMRESPONSE  Create object from server response

            out = BFModelProperty.empty(length(resp),0);
            for i = 1: length(resp)
                r = resp(i);
                out(i) = BFModelProperty(session, r.id, r.index,r.locked, ...
                    r.default,r.conceptTitle,r.createdAt,r.updatedAt,...
                    r.required,r.name,r.displayName,r.dataType,...
                    r.description,r.defaultValue);
            end
        end
    end
end

