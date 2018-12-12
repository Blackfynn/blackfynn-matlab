classdef (Sealed) BFTimeseries < BFDataPackage
    % BFTIMESERIES  A Timeseries package on Blackfynn
    
    properties (Dependent)
        channels        % Struct of channel objects
        layers          % Array of annotation layers
        startTime       % Signal's start time in usecs
        endTime         % Signal's end time in usecs
    end
    
    properties (Hidden)
        layers_
        channels_
        startTime_
        endTime_
    end
    
    methods
        function obj = BFTimeseries(session, id, name, type)
            % BFTIMESERIES Constructor of the timeseries class.
            
            obj = obj@BFDataPackage(session, id, name, type);
        end
        
        function value = get.startTime(obj)                 
            % GET_STARTTIME gets the start time of the signal.
            %
            if ~isempty(obj.startTime_)
                value = obj.startTime_;
            else
                chs = obj.channels;
                startTimes = [chs.startTime];
                value = min(startTimes);
            end
        end
        
        function value = get.endTime(obj)                   
            % GET_ENDTIME gets the endtime of the signal.
            %
            if ~isempty(obj.endTime_)
                value = obj.endTime_;
            else
                chs = obj.channels;
                endTimes = [chs.endTime];
                value = max(endTimes);
            end
        end
        
        function value = get.channels(obj)                  
            % GET_CHANNELS gets the timeseries channels
            %
            if ~(isempty(obj.channels_))
                value = obj.channels_;
            else
                resp = obj.session_.mainAPI.getTimeseriesChannels(obj.id_);
                value = BFTimeseriesChannel.empty(length(resp),0);
                for i = 1 : length(resp)
                    value(i) = BFTimeseriesChannel.createFromResponse(resp, ...
                        obj.session_);
                end
                obj.channels_ = value;
            end
        end
        
        function value = get.layers(obj)                    
            % GET_LAYERS gets all the annotation layers for the timeseries
            % package.
            
            if (~isempty(obj.layers_))
                value = obj.layers_;
            else
                resp = obj.session_.mainAPI.getAnnotationLayers(obj.id_);           
                res = resp.results;
                value = BFTimeseriesAnnotationLayer.empty(length(res),0);
                for i = 1 : length(res)
                    value(i) = BFTimeseriesAnnotationLayer.createFromResponse(res(i), ...
                        obj.session_, obj);
                end
                obj.layers_ = value;
            end    
        end
        
        function out = getSpan(obj,channels, start, stop)   
            % GETSPAN Returns data for a given span of time and channels.
            %    RESULT = GETSPAN(OBJ, CHANNELS, START, STOP) returns a 2D
            %    array for each channel with the time-stamps and the values of
            %    the timeseries within the given range. CHANNELS is an array of
            %    BFTIMESERIESCHANNEL objects, START is the start of the range
            %    relative to the start-time of the timeseries object in
            %    microseconds. STOP is the end of the range relative to the
            %    start-time of the package in microseconds.
            %
            %
            %    Examples:
            %       % Return first 10 seconds of data on all channels
            %       TS = BFTimeseries(...)
            %       DATA = TS.GETSPAN(TS.channels, 0, 10e6)
            %
            %       % Return minute 5 through 10 on first two channels
            %       START = 5*60*1e6
            %       STOP = 10*60*1e6
            %       DATA = TS.GETSPAN(TS.channels(1:2), START, STOP) 
            %
            %    see also:
            %       BFTimeSeries, BFTimeSeriesChannel

            % Create channel array structure for request
            chan_array = struct();
            for i=1:length(channels)
                chan_array(i).id =  channels(i).id_;
                chan_array(i).rate = channels(i).rate;
            end
            ch_ids = {chan_array.id};
            max_rate = max([chan_array.rate]);

            % Set chunk size (10,000 values per chunk)
            chunk_size = 1e6* (10000/max_rate);

            % Create Websocket connection to Blackfynn Agent
            ws_ = BFAgentIO(obj.session_, obj.id_);
            cmd = struct( ...
                'command', "new", ...
                'session', obj.session_.api_key, ...
                'packageId', obj.id_, ...
                'channels', chan_array, ...
                'startTime', uint64(start), ...
                'endTime', uint64(stop), ...
                'chunkSize', uint64(chunk_size), ...
                'useCache', true);
            cmd_encode = jsonencode(cmd);
            ws_.send(cmd_encode);

            % Wait for async callback to return with data
            waitfor(ws_.received_data.handle, 'Empty', false);
            data = ws_.received_data.get('data');

            % Convert data to Blackfynn Cell-Array
            ks = data.keySet;
            ks_it = ks.iterator;
            out = cell(ks.length,1);
            br = blackfynn.Request('');
            while ks_it.hasNext
                curChId = ks_it.next;
                loc = find(strcmp(ch_ids,curChId),1);
                out{loc} = double(br.parseTimeSeriesList(data.get(curChId)));
            end
        end
    
        function out = createLayer(obj, name, varargin)     
            % CREATE_LAYER Creates an annotation layer
            %   LAYER = CREATELAYER(OBJ, 'name') creates a new annotation
            %   layer for the current timeseries object. 
            %
            %   LAYER = CREATELAYER(OBJ, 'name', 'description') creates a
            %   layer with a name and a description.
            %
            %   For example:
            %
            %       ts.createLayer('Eye Movements', 'Description of layer')

            narginchk(2,3);

            % add description is specified as input
            description = '';
            if nargin > 2
                description = varargin{1};
            end

            % check if layer already exists
            cur_layers = obj.layers;
            for i = 1 : length(cur_layers)
                if strcmp(name,cur_layers(i).name)
                    layer = cur_layers(i);
                end
            end

            % if layer does not exist, create
            if ~exist('layer', 'var')
                resp = obj.session_.mainAPI.createAnnotationLayer(obj.id_, name, description);
                out = BFTimeseriesAnnotationLayer.createFromResponse(resp, obj.session_);
            else
                out = BFTimeseriesAnnotationLayer.createFromResponse(layer, obj.session_);
            end
            
            obj.layers_ = [];
        end
    
        function layers = listLayers(obj)                   
            % LISTLAYERS returns a MATLAB Table with annotation layer info
            %   LAYERS = LISTLAYERS(OBJ) returns a MATLAB table
            %   representing the annotation layers that exist for the
            %   timeseries object.
            %
            %   For example:
            %       ts.LISTLAYERS()
            %
            %         +----------+------------+-------------------+
            %         | ID       | Name       | Description       |
            %         +----------+------------+-------------------+
            %         | layer_id | layer_name | layer_description |
            %         +----------+------------+-------------------+
            %
            
            l = obj.layers;
            col_names = {'ID', 'Name', 'Description'};
            out_table = cell2table(cell(length(l), length(col_names)));
            out_table.Properties.VariableNames = col_names;
            for i=1:length(l)
                out_table(i,1) = {char(string(l(i).layerId))};
                out_table(i,2) = {l(i).name};
                out_table(i,3) = {l(i).description};
            end
            layers = out_table;
        end
    
        function obj = deleteLayer(obj, layer)              
            % DELETELAYER Removes layer associated with timeseries object
            %   OBJ = DELETELAYER(OBJ, LAYER) removes an annotationlayer
            %   from the timeseries object. LAYER is an object of class
            %   BFTIMESERIESANNOTATIONLAYER.
            %

            assert(isa(layer,'BFTimeseriesAnnotationLayer'),...
                'Incorrect input argument');
            
            resp = obj.session_.mainAPI.deleteAnnotationLayer(obj.id_, ...
                layer.id_);
            
            obj.layers_ = [];

        end
    end
  
    methods (Static, Hidden)
      
      function out = merge_struct(old,new, ind)
          % MERGE_STRUCT handles the channel responses for a ts package
          %
          fields=fieldnames(new);
          for fn=fields'
              fn=char(fn);
              if ~(isfield(old(ind-1), fn))
                  for j = 1 : length(old)
                      if ~(isfield(old(j),fn))
                        old(j).(fn)='';
                      end
                  end
                  old = orderfields(old(:), new);
              end
          end
          out=old;
      end
      
      function out = add_field(old, new, ind)
          % ADD_FIELD supporting method to handle channel responses.
          %
          fields=fieldnames(new(ind-1));
          for fn=fields'
              fn=char(fn);
              if ~(isfield(old.content, fn))
                  old.content.(fn)='';
              end
          end
          out = old.content;
      end
      
      function out = get_chan_struct(chans)
          % GET_CHAN_STRUCT organize channels in a way that makes sense.
          %
          fieldStart = 'start';
          fieldEnd = 'end';
          fieldSpikes = 'spikeDuration';
          
          for i = 1:length(chans)
              [chans(i).content.('startTime')] = chans(i).content.(fieldStart);
              [chans(i).content.('endTime')] = chans(i).content.(fieldEnd);
              [chans(i).content] = rmfield(chans(i).content, fieldStart);
              [chans(i).content] = rmfield(chans(i).content, fieldEnd);
              
              if (i > 2)
                field_in_num = length(fieldnames(chans(i).content));
                field_out_num = length(fieldnames(out(i-1)));
              
                if ((field_in_num ~= field_out_num) ||...
                        ~(strcmp(out(i-1).channelType, chans(i).content.channelType)))
                    if (field_in_num > field_out_num)
                        out = BFTimeseries.merge_struct(out, chans(i).content, i);
                    else
                        chans(i).content = BFTimeseries.add_field(chans(i), out, i);
                    end
                end
              end
              if ~(isfield(chans(i).content, fieldSpikes))
                  chans(i).content.(fieldSpikes) = '(null)';
              end
              out(i) = chans(i).content;
          end
      end
      
      function out = createFromResponse(resp, session)
          % CREATEFROMRESPONSE create a ts object from an API response
          %
          content = resp.content;
          chans = struct();
          out = BFTimeseries(session, content.id, content.name, ...
              content.packageType);
          out.datasetId =  content.datasetId;
          out.state = content.state;
      end
      
    end
end