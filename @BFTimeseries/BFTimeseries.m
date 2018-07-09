classdef (Sealed) BFTimeseries < BFDataPackage
    % Object that represents a timeseries package
    %
    properties (Dependent)
        channels % Returns struct of channel objects associated with the package.
        layers
        startTime % Signal's start time in usecs
        endTime % Signal's end time in usecs
    end
    
    properties (Hidden)
        layers_
        channels_
        startTime_
        endTime_
        package
    end
    
    methods
        function obj = BFTimeseries(varargin)
            % BFTIMESERIES Base class used for ``BFTimeseries`` objects
            %
            % Args:
            %       ID (str): timeseries package's ID
            %       name (str): name of the timeseries package
            %
            % Returns:
            %           ``BFTimeseries``: Timeseries object
            %
            obj = obj@BFDataPackage(varargin{:});
            obj.channels_=varargin{5};
            
            obj.session = varargin{1}.api_key;
            obj.package = varargin{2}; 
                     
            
        end
        
        function delete(obj)
            try
                obj.ws_.close();
            catch ME
                fprintf('error closing websocket')
            end
            
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
                resp = obj.get_channels();
                for i = 1 : length(resp)
                    value(i) = BFTimeseriesChannel.createFromResponse(resp, ...
                        obj.session);
                end
                obj.channels_ = value;
            end
            value=obj.channels_;
        end
        
        function value = get.layers(obj)
            % GET_LAYERS gets all the annotation layers for the timeseries
            % package.
            %
            if (~isempty(obj.channels_))
                value = obj.layers_;
            else
                resp = obj.get_channels();
                for i = 1 : length(resp)
                    value(i) = BFTimeseriesAnnotationLayer.createFromResponse(resp, ...
                        obj.session);
                end
                obj.layers_ = value;
            end    
        end
        
    function out = getSpan(obj,channels, start, stop)
      % GETSPAN gets timeseries data between ``start`` and ``end`` times
      % for specified channels.
      %
      % Args:
      %         channels (struct): channel or channels to retrieve data from
      %         start (int): start time for the retrieved interval in usecs
      %         end (int): end time for the retrieved interval in usecs
      %
      % Returns:
      %         matrix: Matrix of doubles, where the first column represents
      %         the time, and the remaining columns contain the channel
      %         data.
      %
      % Examples:
      %             Get 1 second of data for all the channels in ``ts``, a
      %             ``timeseries`` object::
      %                 
      %                 >> data = ts.getSpan(ts.channels, ts.startTime, ts.startTime+1000000);
      %
      %             Get 5 seconds of data for channels 2 through 4 of the
      %             ``ts`` object::
      %
      %                 >> data = ts.getSpan(ts.channels(2:4), ts.startTime, ts.startTime+5000000)
      %
      %
      % Note:
      %         The start and end times are relative to the starTime and
      %         endTime specified in the package. To find out the start
      %         and end times, you can use ``ts.startTime`` and ``ts.endTime``
      %         where ``ts`` is a ``timeseries`` object.
      %
      % Warning:
      %         The maximum amount of data points that can be obtained at a 
      %         time is 1000. To obtain more data, you can use an iterative
      %         approach.
      %

      chan_array = struct(); %cell(1,length(channels));
      for i=1:length(channels)
        chan_array(i).id =  channels(i).id;
        chan_array(i).rate = channels(i).rate;
      end

    cmd = struct( ...
        'command', "new", ...
        'session', obj.session, ...
        'packageId', obj.package, ...
        'channels', chan_array, ...
        'startTime', uint64(start), ...
        'endTime', uint64(stop), ...
        'chunkSize', uint64(5000000), ...
        'useCache', true);
    
    cmd_encode = jsonencode(cmd);  
    
    % Create Websocket connection to Blackfynn Agent
      
    ws_ = BFAgentIO(obj.session, obj.package);
    ws_.send(cmd_encode);
    
    % Wait for async callback to return with data
    waitfor(ws_.received_data.handle, 'Empty', false);
    
    % Get data
    data = ws_.received_data.get('data');
    
    ks = data.keySet;
    ks_it = ks.iterator;
    out = struct();
    ch = 1;
    while ks_it.hasNext
        curChId = ks_it.next;
        curCh = data.get(curChId);
        chDat = zeros(curCh.size,2);

        dat_it = curCh.iterator;
        ix = 1;
        while dat_it.hasNext
            nextVal = dat_it.next;
            chDat(ix,1) = nextVal.getTime;
            chDat(ix,2) = nextVal.getValue;
            ix = ix+1;
        end
        out.(sprintf('ch_%i',ch)) = chDat;
        ch = ch+1;
    end
    
    
    end
    
    function show_channels(obj)
        % SHOW_CHANNELS lists the channel IDs, Names and Types in a
        % timeseries package.
        % 
        % Examples:
        %
        %           Show channels for ``ts``, a timeseries object::
        %
        %               >> ts.show_channels
        %               0. ID: "N:channel:43dd423a-6f8f-4fe9-b8c3-9d4444449f7b", Name: "chan000", Type: "CONTINUOUS"
        %               1. ID: "N:channel:ef222470-e947-472a-b975-4dad95ac8ccd", Name: "chan006", Type: "CONTINUOUS"
        %               2. ID: "N:channel:e663cdc1-68a4-4a9f-3333-55681b65562a", Name: "chan004", Type: "CONTINUOUS"
        %               3. ID: "N:channel:31419dfc-1dc0-4eac-b9d9-6trtf4215dff", Name: "chan020", Type: "CONTINUOUS"
        %
        len_chan = length(obj.channels);
        
        for i = 1 : len_chan
            fprintf('%d. ID: "%s", Name: "%s", Type: "%s"\n',...
                (i-1), obj.channels(i).id, obj.channels(i).name, ...
                obj.channels(i).channelType);
        end
    end
    
    function out = get_channel(obj, chan_id)
        % GET_CHANNELS gets the channels for a ts package.
        %
        % Args:
        %       ID (str): ID for the channel that is being retrieved
        %
        % Returns:
        %           struct: Channel object
        %
        % Examples:
        %
        %           Get a channel that belongs to ``ts``, a timeseries
        %           package::
        %
        %               >> chan = ts.get_channel("N:channel:43dd423a-6f8f-4fe9-b8c3-9d4444449f7b");
        %
        % Note:
        %
        %       This is equivalent to doing ``ts.channels(i)``, where ``i``
        %       is the number of the channels in the channel list. However,
        %       if the user needs to obtain a specific channel, it is best
        %       to retrieve it through its ID.
        %
        fieldSpikes = 'spikeDuration';
        uri = sprintf('%s%s%s%s', obj.session.host,'timeseries/', ...
            obj.id, '/channels/', chan_id);
        params = {};
        out = obj.session.request.get(uri, params);
        out = out.content;
        if ~(isfield(out, fieldSpikes))
            out.(fieldSpikes) = '(null)';
        end
    end
    
    function out = insert_annotation(obj, name, label, varargin)
        % INSERT_ANNOTATION Adds an annotation in the layer specified by
        % the user.
        %
        % Args:
        %       name (str): Layer in which to create the annotation
        %       label (str): Label for the annotation
        %       start (int, optional): start time (in usecs) for the annotation (default start time of signal)
        %       end (int, optional): end time (in usecs) for the annotation (default end time of signal)
        %       channelIds (str, optional): channel IDs for the channels that are annotated (all channels default)
        %       description (str, optional): description for the generated annotation
        %
        % Example:
        %
        %           Add a new annotation with label "Atonic Seizure" in a layer called "Seizures" for
        %           ``ts``, a timeseries object::
        %
        %               >> event = ts.insert_annotation('Seizures', 'Atonic Seizure', 'start', ts.startTime+10000000, 'end', ts.startTime+18000000);
        %
        % Note:
        %       If specific channels are selected for the annotations, they
        %       must be defined as string arrays::
        %
        %           >> channels = ["N:channel:????????-????-????-????-????????????", "N:channel:????????-????-????-????-????????????"]
        %
        layer = obj.create_layer(name, varargin{:});
        uri = sprintf('%s%s%s%s%d%s', obj.session.host,'timeseries/', ...
            obj.id,'/layers/', layer.layerId, '/annotations');
        message = obj.load_annotation_params(name, label, layer.layerId, varargin{:});
        out = obj.session.request.post(uri, message);
        out = BFTimeseriesAnnotation.createFromResponse(out, obj.session);
    end
    
    function out = get_layers(obj)
        % GET_LAYERS gets the annotation layers for a timeseries package
        %
        % Returns:
        %           ``BFTimeseriesAnnotationLayer``:  Annotation layer object
        %
        % Examples:
        %
        %           get all the layers for ``ts``, a timeseries object::
        %
        %               >> ts.get_layers
        %
        %               ans = 
        %
        %                   1×7 BFTimeseriesAnnotationLayer array with properties:
        %
        %                       name
        %                       timeSeriesId
        %                       layerId
        %                       description
        %
        uri = sprintf('%s%s%s%s', obj.session.host,'timeseries/',...
            obj.id,'/layers');
        params = {};
        out = obj.session.request.get(uri, params);
        out = out.results;
        
        % handle response
        layer = struct();
        for i = 1 : length(out)
            if i == 1
                layer = BFTimeseriesAnnotationLayer.createFromResponse(out(i),...
                    obj.session);
            else
               layer = [BFTimeseriesAnnotationLayer.createFromResponse(out(i),...
                   obj.session), layer];
            end
        end
        out = layer;
    end
    
    function out = create_layer(obj, name, varargin)
        % CREATE_LAYER Creates an annotation layer for the given timeseries
        % object.
        %
        % Args:
        %       name (str): name of the layer to be created
        %       description (str, optional): description of the layer to be created
        %
        % Returns:
        %          ``BFTimeseriesAnnotationLayer``: object for the created
        %          layer
        %
        % Examples:
        %       
        %           Create a new layer called "Eye Movements" for ``ts``, a timeseries object::
        %
        %               >> ts.create_layer('Eye Movements', 'description', 'Layer for eye movement annotations')
        %         
        %                   ans =
        %
        %                       BFTimeseriesAnnotationLayer with properties:
        %
        %                           name: 'Eye Movements'
        %                           timeSeriesId: 'N:package:54d39b0a-8bd9-4993-3333-3c4e8etdre05'
        %                           layerId: 394
        %                           description: 'Layer for eye movement annotations'
        %
        %
        %
        description = '';
        
        % add description is specified as input
        for i = 1 : length(varargin)
            if strcmp(varargin(i), 'description')
                description = varargin(i+1);
            end
        end
        
        % check if layer already exists
        cur_layers = obj.get_layers;
        for i = 1 : length(cur_layers)
            if strcmp(name,cur_layers(i).name)
                layer = cur_layers(i);
            end
        end
        
        % if layer does not exist, create
        if ~exist('layer', 'var')
            uri = sprintf('%s%s%s%s', obj.session.host, 'timeseries/', ...
                obj.get_id, '/layers');
            message = struct('name', name,...
                'description', description);
            out = obj.session.request.post(uri, message);
            out = BFTimeseriesAnnotationLayer.createFromResponse(out,...
                    obj.session);
        else
            out = BFTimeseriesAnnotationLayer.createFromResponse(layer,...
                    obj.session);
        end
    end
    
    function show_layers(obj)
        % SHOW_LAYERS displays all the annotation layers for the given
        % timeseries object in the console.
        %
        % Example:
        %           Show all the layers for ``ts``, a timeseries object::
        %
        %               >> ts.show_layers
        %               ID: "387", Name: "Artifacts", Description: "Layer for artifact annotations"
        %               ID: "367", Name: "Default", Description: "Default Annotation Layer"
        %               ID: "390", Name: "Seizures", Description: "Layer for seizure annotations"
        %
        l = obj.get_layers;
        for i  = 1 : length(l)
            fprintf('ID: "%d", Name: %s, Description: "%s"\n', ...
                l(1,i).layerId, l(1,i).name, l(1,i).description)
        end
    end
    
    function out = layers2table(obj)
        % LAYERS2TABLE stores all of the layers associated with a
        % timeseries object in a MATLAB table. The output is a table that
        % looks as follows:
        %
        %         +----------+------------+-------------------+
        %         | ID       | Name       | Description       |
        %         +----------+------------+-------------------+
        %         | layer_id | layer_name | layer_description |
        %         +----------+------------+-------------------+
        %
        % Examples:
        %
        %           Store all the layers associated with ``ts``, a
        %           timeseries object in a MATLAB table::
        %
        %               >> out_table = ts.layers2table;
        %               >> out_table
        %
        %                   3×3 table
        %
        %                       ID                 Name                       Description
        %                     _____    ___________________________    __________________________
        %
        %                     '387'    'Artifacts'                    'Layer for artifact annotations'
        %                     '367'    'Default'                      'Default Annotation Layer'
        %                     '390'    'Seizures'                     'Layer for seizure annotations'
        %
        %
        l = obj.get_layers;
        col_names = {'ID', 'Name', 'Description'};
        out_table = cell2table(cell(length(l), length(col_names)));
        out_table.Properties.VariableNames = col_names;
        for i=1:length(l)
            out_table(i,1) = {char(string(l(i).layerId))};
            out_table(i,2) = {l(i).name};
            out_table(i,3) = {l(i).description};
        end
        out = out_table;
    end
    
    function delete_layer(obj, id)
        % DELETE_LAYER Removes layer associated with timeseries object
        %
        % Args:
        %       id (int): ID of the layer to be deleted
        %
        % Examples:
        %
        %           delete layer with ID 384 and associated to ``ts``,
        %           a timeseries object::
        %
        %               >> ts.delete_layer(384)
        %
        uri = sprintf('%s%s%s%s%d', obj.session.host, 'timeseries/', ...
            obj.get_id, '/layers/', id);
        message = '';
        obj.session.request.delete(uri, message);
    end
    
  end
  
  methods (Access = private)
      
   function out = get_channels(obj)
      % GET_CHANNELS gets the channels for a ts package
      %
      uri = sprintf('%s%s%s%s', obj.session.host,'timeseries/', obj.id,...
          '/channels');
      params = {};
      out = obj.session.request.get(uri, params);
   end
    
    function out = load_annotation_params(obj, name, label, layer_id, ...
            varargin)
       % LOAD_ANNOTATION_PARAMS Parameter parser
       %
    
       % create default channel list
       %
       channelList = strings(1, length(obj.channels));
       for i = 1 : length(obj.channels)
           channelList(i) = obj.channels(i).id;
       end
       
       defaultDescription = '';
       defaultStart = obj.startTime;
       defaultEnd = obj.endTime;
       defaultChannels = obj.channels;
       
       p = inputParser;
       addParameter(p, 'name', name);
       addParameter(p, 'label', label);
       addParameter(p, 'start', defaultStart);
       addParameter(p, 'end', defaultEnd);
       addParameter(p, 'layer_id', layer_id);
       addParameter(p, 'channelIds', channelList);
       addParameter(p, 'description', defaultDescription);
       
       parse(p,varargin{:})
       
       % format parsed parameters
       results_cell = struct2cell(p.Results);    
       params=struct();
       for i = 1:length(p.Parameters)
           params.(p.Parameters{i})=results_cell{i};
       end
       
       out = params;
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
          if (isfield(resp, 'channels'))
              chans = BFTimeseries.get_chan_struct(resp.channels);
          end
          out = BFTimeseries(session, content.id, content.name, ...
              content.packageType, chans);
          out.datasetId =  content.datasetId;
          out.state = content.state;
      end
      
    end
end