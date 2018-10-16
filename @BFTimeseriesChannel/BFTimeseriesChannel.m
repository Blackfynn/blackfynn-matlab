classdef (Sealed) BFTimeseriesChannel < BFBaseDataNode
    %BFTIMESERIESCHANNEL Representation of a timeseries channel
  
  properties
    startTime       % Start time of channel in us
    endTime         % End time of channel in us
    unit            % Boolean indicating channel is unit-data
    rate            % Sampling rate of channel in Hz
    channelType     % Type of channel
    group           % Group that channel belongs to
  end
    
  methods (Sealed = true)
    function obj = BFTimeseriesChannel(session, id, name)
        % BFTIMESERIESCHANNEL Constructor of BFTIMESERIESCHANNEL class.
        %   OBJ = BFTIMESERIESCHANNEL(SESSION, 'id', 'name') creates an
        %   instance of the BFTIMESERIESCHANNEL class where SESSION is an
        %   object of type BFSESSION, 'id' is the Blackfynn id of the
        %   channel and 'name' is the name of the channel.
        
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
end