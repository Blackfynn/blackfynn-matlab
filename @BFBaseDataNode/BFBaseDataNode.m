classdef (Abstract) BFBaseDataNode < BFBaseNode & matlab.mixin.Heterogeneous
    % The ``BFBaseDataNode`` class provides the basic methods for all of
    % the presented data models.
    %
  properties(Access = private)
    parent
  end
  properties (Hidden);
    id
  end
  
  properties
    name = '' % Name of the element as a string
    type % Type of the element. This property can adopt values such as ``Dataset``, ``DataPackage`` or ``Collection``.
    props = struct()
  end
  
  methods
    function obj = BFBaseDataNode(varargin)
      % BFBASEDATANODE Is a method that creates a base Blackfynn object with a 
      % ``name`` and a ``type``.
      %
      obj = obj@BFBaseNode(varargin{:});
      
      if nargin > 0
        obj.id = varargin{2};
        obj.name = varargin{3};
        obj.type = varargin{4};
        
      end
    end
    
    function out = update(obj)
        %UPDATE Updates the current object in the platform.
        % 
        % Examples:
        %
        %           Delete a package in ``my_collection`` and update object in 
        %           the platform and locally::
        %
        %               >> col.delete(pkg) # delete package
        %               >> col = col.update # update
        %
        id = obj.get_id;
        switch class(obj)
            case {'BFTimeseries','BFCollection',...
                    'BFDataPackage', 'BFTabular'}
                out = obj.update_package(id);
            otherwise
                error('Cannot update object of class %s', class(obj));
        end
        
    end
    
  end
  
  methods (Static)
    function out = createFromResponse(resp, session)
      % Creates an object from a GET request's response.
      % 
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
  
  methods (Hidden)
      function out = update_package(obj, id)
          %UPDATE_PACKAGE Update package in the platform
          %
          uri = sprintf('%s%s%s', obj.session.host, 'packages/', id);
          params = struct(...
              'name', obj.name,...
              'state', obj.state,...
              'packageType', obj.type);
          resp = obj.session.request.put(uri, params);
          out = BFBaseDataNode.createFromResponse(resp, obj.session);
      end
  end
  
  methods (Static, Sealed, Access = protected)
      function default_object = getDefaultScalarElement
          %GETDEFAULTSCALARELEMENT Get default scalar element
          %
          default_object = BFCollection('','','','');
      end
  end

end