classdef BFDataPackage < BFBaseDataNode
  % BFDATAPACKAGE Represents any datapackage on the platform.
  
  properties (Hidden)
      datasetId         % The ID of the dataset the package belongs to
      state             % The state of the package in the platform
      props = struct()  % Attributes associated with a data node
  end
  
  methods
    function obj = BFDataPackage(session, id, name, type)
        %BFDATAPACKAGE Constructor for BFDATAPACKAGE
        %   OBJ = BFDATAPACKAGE(SESSION, 'id', 'name', 'type') creates a
        %   BFDATAPACKAGE instance where SESSION is an instance of
        %   BFSESSION, 'id' is the id of the package, 'name' is the name of
        %   the package and 'type' is the type of the package.
      
      obj = obj@BFBaseDataNode(session, id, name, type);
    end
    
    function success = move(obj, dest)          
        % MOVE  Moves objects to a destination collection
        %   OBJ = MOVE(OBJ, DEST) moves OBJ to a new destination DEST
        %   where DEST is a BFFOLDER, or BFDATASET object where the OBJ
        %   will be moved to.
        %   
        %   OBJ = MOVE(OBJ, 'dest') moves OBJ to new destination 'dest'
        %   where 'dest' is the id of the folder or dataset that OBJ is
        %   moved to.
        %
        %   Example:
        %       
        %       BF = Blackfynn()
        %       PKG = BF.dataset(1).item(1)
        %       FOLDER = BF.dataset(1),item(2)
        %       PKG.MOVE(FOLDER)
        %
        %       PKG.MOVE(''N:package:ae8d7f6f-f35a', FOLDER)
        %
        %   Note:
        %       Data Packages cannot be moved across datasets or
        %       between organizations.
        %

        destid = dest;
        if isa(dest,'BFBaseCollection')
            destid = dest.get_id;
        end

        thingIds{length(obj)} = '';
        for i = 1 : length(obj)
            thingIds{i} = obj(i).id_;
        end

        success = obj.session_.mainAPI.move(thingIds, destid);
        
        % Now move these objects in the MATLAB client
        obj.session_.updateCounter = obj.session_.updateCounter + 1;
        
    end

  end
  
  methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/viewer/%s',obj.session_.web_host,obj.session_.org,obj.datasetId,obj.id_);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s.empty)">Methods</a>',obj.id_,url,class(obj));
            else
                s = '';
            end
        end
  end
  
  methods (Static)
    function out = createFromResponse(resp, session)
      %CREATEFROMRESPONSE  Create object from server response
      
      content = resp.content;
      out = BFDataPackage(session, content.id, content.name, content.packageType);
      out.state = content.state;
      out.datasetId = content.datasetId;
    end
  end
  
end
