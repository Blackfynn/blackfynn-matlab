classdef BFLinkedModelProperty < BFBaseModelProperty
    %BFLINKEDMODELPROPERTY A class representing a Linked Model Property 
    %   Models in the Blackfynn platform can have any number of
    %   properties. Properties have have different types, and have various
    %   attributes associated with them. These are reflected in the
    %   MODELPROPERTY class. Linked Model Properties point to other records
    %   
    %   See also:
    %       BFModel, BFBaseModelProperty
    
    properties
        toModel
    end
    
    properties (Hidden)
        toModelId_
    end
    
    methods
        function obj = BFLinkedModelProperty(varargin)
            %BFMODELPROPERTY Construct an instance of this class
            % Args: Empty, or [session, id, index, locked, default,
            % conceptTitle, createdAt, updatedAt, required, name,
            % displayName, dataType, description, defaultValue]

            narginchk(12,12);
            
            obj = obj@BFBaseModelProperty(varargin{1:9});
            obj.name = varargin{10};
            obj.displayName = varargin{11};
            obj.toModelId_ = varargin{12};
        end
        
        function out = get.toModel(obj)
            out = obj.toModelId_;
        end
    end
    
    methods (Access=protected, Sealed)
      function displayNonScalarObject(~)
          
          % TODO: implement this.
          fprintf('Display of arrays of heterogeneous objects not supported.\n\n');
      end
    end
    
    methods (Static)
        function out = createFromResponse(resp, session)
          %CREATEFROMRESPONSE  Create object from server response

            out = BFLinkedModelProperty.empty(length(resp),0);
            for i = 1: length(resp)
                r = resp(i).link;
                out(i) = BFLinkedModelProperty(session, r.id, r.position, false, ...
                    true, false,r.createdAt,r.updatedAt,...
                    false,r.name,r.displayName,r.to);
            end
        end
    end
end

