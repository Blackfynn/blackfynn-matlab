classdef (Sealed) BFTimeseriesAnnotation < BFBaseNode
    % Object that represents a timeseries annotation
    
    properties
        name                % Name of the layer the annotation is associated to
        label               % Annotation's label
        description         % Annotation's description
        startTime           % Annotation's start time
        endTime             % Annotation's end time
    end
    
    properties (Hidden)
        timeSeriesId        % ID of the timeseries package the annotation is associated to
        channelIds          % IDs for the channels the annotation is associated to
        layerId             % ID of the layer the annotation is associated to
        userId              % ID of the user that created the annotation
    end
    
  methods
    function obj = BFTimeseriesAnnotation(session, id, timeSeriesId, ...
            channelIds, layerId, name, label, description, userId, ...
            startTime, endTime)
         % BFTIMESERIESANNOTATION Base class used for
         % ``BFTimeseriesAnnotation`` objects
         
         obj = obj@BFBaseNode(session, id);
         
         obj.timeSeriesId = timeSeriesId;
         obj.channelIds = channelIds;
         obj.layerId = layerId;        
         obj.name = name;
         obj.label = label;
         obj.description = description;
         obj.userId = userId;
         obj.startTime = startTime;
         obj.endTime = endTime;
    end

  end
  
  methods(Static, Hidden)
      function out = createFromResponse(resp, session)
          % CREATEFROMRESPONSE creates object from request's response
          
          content = resp;
          out = BFTimeseriesAnnotation(session, content.id,...
              content.timeSeriesId, content.channelIds, ...
              content.layerId, content.name, content.label, ...
              content.description, content.userId, ...
              content.start, content.end);
      end
  end

end