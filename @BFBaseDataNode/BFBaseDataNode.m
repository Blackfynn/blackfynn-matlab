classdef (Abstract) BFBaseDataNode < BFBaseNode & matlab.mixin.Heterogeneous
    % BFBASEDATANODE Abstract class underlying all package representations.
    %
    %   All packages on the blackfynn platform share a number of
    %   properties. These properties are captured in the BFBASEDATANODE
    %   class. The BFBASEDATANODE class entends the BFBASENODE class.
    
  properties
    name = ''           % Name of the datanode
    type = ''           % Type of the datanode 
  end
  

  methods
    function obj = BFBaseDataNode(session, id, name, type)
        %BFBASEDATANODE Constructor for BFBASEDATANODE class
        %   OBJ = BFBASEDATANODE(SESSION, 'id', 'name', 'type') creates an
        %   instance of the class BFBASEDATANODE. SESSION is an instance of
        %   BFSESSION class, 'id' is the Blackfynn id of the object, 'name'
        %   is the name of the datanode, and type is the type of datanode.
        
        narginchk(4,4);
        
        obj = obj@BFBaseNode(session, id);
        obj.name = name;
        obj.type = type;
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
                obj.session_.mainAPI.updatePackage(obj.id_, obj.name, obj.state, obj.type);
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
       
      out = BFCollection.empty(length(resp),0);

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
          % GETDEFAULTSCALARELEMENT Get default scalar element
          %     OBJ = GETDEFAULTSCALARELEMENT() returns the default object
          %     for this class. The implementation of this method is
          %     required by the Heterogeneous mixin class.
          
          default_object = BFCollection('','','','');
      end
  end

end