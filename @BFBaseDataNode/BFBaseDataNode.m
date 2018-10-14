classdef (Abstract) BFBaseDataNode < BFBaseNode & matlab.mixin.Heterogeneous
    % BFBASEDATANODE Abstract class underlying all package representations. 
    
  properties
    name = ''           % Name of the data node
    type = ''           % Type of the data node 
  end
  

  methods
    function obj = BFBaseDataNode(varargin)
      % Args: Empty, or [session, id, name, type]  
      obj = obj@BFBaseNode(varargin{:});
      
      if nargin
        obj.name = varargin{3};
        obj.type = varargin{4};
      end
    end
    
    function obj = update(obj)
        % UPDATE Updates the current object in the platform.
        %   OUT = UPDATE(OBJ) updates the object on the platform with the
        %   current version of the local object.
        % 
        %   Example:
        %
        %       Delete a package in ``my_collection`` and update object in 
        %       the platform and locally::
        %       
        %       FOLDER = Dataset(1).items(1)
        %       FOLDER.delete(pkg)
        %       FOLDER = FOLDER.update
        
        switch class(obj)
            case {'BFTimeseries','BFCollection','BFDataPackage', ...
                    'BFTabular'}
                obj.session.mainAPI.updatePackage(obj.id, obj.name, obj.state, obj.type);
            otherwise
                error('Cannot update object of class %s', class(obj));
        end
        
    end 
  end
  
  methods (Access=protected, Sealed)
      function displayNonScalarObject(~)
          
          % TODO: implement this.
          fprintf('Display of arrays of heterogeneous objects not supported.\n\n');
      end
  end
  
  methods (Static, Hidden)
    function out = createFromResponse(resp, session)
      % Creates an object from a GET request's response.
       
      out(length(resp)) = BFCollection();

      for i = 1 : length(resp)
        item = resp(i);
        if iscell(item)
            item = resp{i,1};
        end
        content = item.content;
        switch content.packageType
            case 'DataSet'
                out(i) = BFDataset.createFromResponse(item, session);
            case 'Collection'
                out(i) = BFCollection.createFromResponse(item, session);
            case 'TimeSeries'
                out(i) = BFTimeseries.createFromResponse(item, session);
            case 'Tabular'
                out(i) = BFTabular.createFromResponse(item, session);
            otherwise
                out(i) = BFDataPackage.createFromResponse(item, session);
        end
        
        if isfield(out(i),'props')
            props = struct();
            for j = 1 : length(item.properties)
              curLayer = item.properties(j);
              validLayer = matlab.lang.makeValidName(curLayer.category);

              props.(validLayer) = struct();

              for k = 1 : length(curLayer.properties)
                validKey = matlab.lang.makeValidName(curLayer.properties(k).key);
                props.(validLayer).(validKey) = curLayer.properties(k).value;
              end
            end

            out(i).props = props;
        end
      end
    end
  end

  methods (Static, Sealed, Access = protected)
      function default_object = getDefaultScalarElement
          %GETDEFAULTSCALARELEMENT Get default scalar element
          %
          % This is required for Heterogeneous mixin
          
          default_object = BFCollection('','','','');
      end
  end

end