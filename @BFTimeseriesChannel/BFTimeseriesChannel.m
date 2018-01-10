classdef (Sealed) BFTimeseriesChannel < BFBaseDataNode
  
  properties
    startTime
    endTime
    unit
    rate
    channelType
    group
  end
    
  methods (Sealed = true)
    
    function obj = BFTimeseriesChannel(session, id, name)
         obj = obj@BFBaseDataNode(session, id, name, 'TimeseriesChannel' );
    end

  end
  
  methods(Static, Sealed = true)
    function out = createFromResponse(resp, session)
      content = resp.content;
      out = BFTimeseriesChannel(session, content.id, content.name);
      
      out.startTime = content.start;
      out.endTime = content.end;
      out.unit = content.unit;
      out.rate = content.rate;
      out.channelType = content.channelType;
      out.group = content.group;
      
    end
  end
  
  methods (Static, Access = private, Sealed = true)

  end

end