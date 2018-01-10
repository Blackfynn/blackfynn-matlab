classdef BFDataPackage < BFBaseDataNode
  %BFDATAPACKAGE is a class for all non-specific data classes (i.e classes that 
  % do not need specialized methods).
  %
  
  properties
      datasetId
      state
  end
  
  methods
    function obj = BFDataPackage(varargin)
      %BFDATAPACKAGE is the core data object representation on the platform
      %
      % Args:
      %         name (str): The name of the data package
      %         package_type (str): Type of the package (``TimeSeries``, ``Tabular``, etc.)
      %
      % Returns:
      %          ``BFDataPackage``: A DataPackage object.
      %
      %
      % Note:   
      %       The ``package_type`` must be a supported package type. See 
      %       our data type registry for supported values.
      %
      obj = obj@BFBaseDataNode(varargin{:});
    end
  end
  
  methods (Static)
    function out = createFromResponse(resp, session)
      %CREATEFROMRESPONSE  Create object from server response
      %
      content = resp.content;
      out = BFDataPackage(session, content.id, content.name, content.packageType);
      out.state = content.state;
      out.datasetId = content.datasetId;
    end
  end
  
end
