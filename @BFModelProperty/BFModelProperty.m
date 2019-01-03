classdef BFModelProperty < BFBaseModelProperty
    %BFMODELPROPERTY A class representing a Model Property on the platform
    %   Models in the Blackfynn platform can have any number of
    %   properties. Properties have have different types, and have various
    %   attributes associated with them. These are reflected in the
    %   MODELPROPERTY class.
    %
    %   See also:
    %       BFModel, BFBaseModelProperty
    
    properties
        dataType        % Data type of property
        description     % Description of property
        defaultValue    % Default value of property
    end
    
    methods
        function obj = BFModelProperty(varargin)
            %BFMODELPROPERTY Construct an instance of this class
            % Args: Empty, or [session, id, index, locked, default,
            % conceptTitle, createdAt, updatedAt, required, name,
            % displayName, dataType, description, defaultValue]

            narginchk(14,14);
            
            obj = obj@BFBaseModelProperty(varargin{1:9});
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

