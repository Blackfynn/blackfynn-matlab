classdef (Abstract) BFBaseDataNode < BFBaseNode & matlab.mixin.Heterogeneous
    % The ``BFBaseDataNode`` class provides the basic methods for all of
    % the presented data models.
    %
  properties(Access = private)
    parent
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
        obj.name = varargin{3};
        obj.type = varargin{4};
        
      end
    end
    
    function id = get_id(obj)
        %GET_ID  Returns the Blackfynn ID for the object. You can
        % use this ID to reference the Blackfynn object in all clients and on
        % the platform.
        %
        %
        % Note:
        %       All of the Blackfynn data objects are identified with a unique
        %       ID of the type
        %       ``N:obj_type:????????-????-????-????-????????????``, where the
        %       ``?`` wildcard represents alphanumeric characters.
        %
        % Examples:
        %
        %           Get the ID of a dataset under your current Organization::
        %
        %               >> dataset_obj.get_id;
        %
        %           Get the ID of a package under a dataset::
        %
        %               >> package_obj.get_id;
        %
        id = obj.id;
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
    
  % end of methods
  end
  
  methods (Access = protected)
    function info = specialPropsInfo(obj)
        % Information about special properties
        %
      info = struct('name',{},'size',[0 0], 'format','');
    end
    
  end
  
  methods (Static)
    function out = createFromResponse(resp, session)
      % Creates an object from a GET request's response.
      % 
      out(length(resp)) = BFCollection();

      for i = 1 : length(resp)
        item = resp(i);
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
    
  % end of static methods
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
      
  % end of methods    
  end

% end of class
end