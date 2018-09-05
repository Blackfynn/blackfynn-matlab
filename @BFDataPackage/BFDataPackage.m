classdef BFDataPackage < BFBaseDataNode
  % BFDATAPACKAGE Represents any datapackage on the platform.
  
  properties (Hidden)
      datasetId
      state
      props = struct()    % attributes associated with a data node
  end
  
  methods
    function obj = BFDataPackage(varargin)
      % Args: Empty, or [session, id, name, type]
      obj = obj@BFBaseDataNode(varargin{:});
    end
    
    function obj = move(obj, dest, varargin)          
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

        uri = sprintf('%s/%s',obj.session.host,'data/move');

        destid = dest;
        if isa(dest,'BFBaseCollection')
            destid = dest.get_id;
        end

        thingIds{length(varargin)} = '';
        for i = 1 : length(varargin)
            thingIds{i} = varargin{i}.get_id;
        end

        if length(varargin) == 1
            thingIds{2} = '';
        end

        message = struct(...
            'things', [],...
            'destination', destid);

        message.things = thingIds;
        obj.session.request.post(uri, message);
    end

  end
  
  methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/viewer/%s',obj.session.web_host,obj.session.org,obj.datasetId,obj.id);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,url,class(obj));
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
