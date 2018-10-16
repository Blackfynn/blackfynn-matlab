classdef BFTimeseriesAnnotationLayer < BFBaseNode
  % BFTIMESERIESANNOTATIONLAYER Object that represents a timeseries annotation layer
  %
  % Annotation layers contain collections of annotations. A timeseries
  % package can have multiple annotation layers, and each annotation layer
  % can have multiple annotations.
  
  properties
    name            % Layer's name
    description     % Layer's description
  end
  
  properties (Hidden)
    timeSeriesId    % ID of the timeseries package
    layerId         % Layer's ID
  end
  
  methods
    function obj = BFTimeseriesAnnotationLayer(varargin)
        % BFTIMESERIESANNOTATIONLAYER Constructor of
        % BFTIMESERIESANNOTATIONLAYER class.
        %   OBJ = BFTIMESERIESANNOTATIONLAYER(SESSION, 'id', 'name',
        %   'ts_id', 'description') creates a timeseries annotationlayer
        %   where SESSION is an instance of the BFSESSION class, 'id' is
        %   the Blackfynn id of the layer, 'name' is the name of the
        %   layer,'ts_id' is the Blackfynn id of the timeseries package the
        %   channel belongs to and 'description' is a description of the
        %   annotation layer.
        
         obj = obj@BFBaseNode(varargin{:});
         if nargin
             obj.name = varargin{3};
             obj.layerId = varargin{2};
             obj.timeSeriesId = varargin{4};
             obj.description = varargin{5};
         end
    end
    
    function out = annotations(obj, varargin)
        % ANNOTATIONS Gets all the annotations for a given layer.
        %   [ANNS, ISALL] = ANNOTATIONS(OBJ)
        %   [ANNS, ISALL] = ANNOTATIONS(..., START, END)
        %   [ANNS, ISALL] = ANNOTATIONS(..., START, END, OFFSET, LIMIT)
        % 
        % Args:
        %       end (int, optional): end time (in usecs) for the interval in which to search for annotations (default 1000000)
        %       start (int, optional): start time (in usecs) for the interval in which to search for annotations (default start time of timeseries data)
        %       
        % Returns: 
        %           ``BFTimeseriesAnnotationLayer``: Annotation object
        %
        % Examples:
        %
        %            get all the annotations for ``ly``, a
        %            ``BFTimeseriesAnnotationLayer`` object that describes a layer for ``ts``, a timeseries object::
        %
        %               >> ly.annotations('end', ts.endTime)
        %
        %               ans =
        %
        %                   1×4 BFTimeseriesAnnotation array with properties:
        %
        %                       annotationId
        %                       timeSeriesId
        %                       channelIds
        %                       layerId
        %                       name
        %                       label
        %                       description
        %                       userId
        %                       startTime
        %                       endTime
        %            
        uri = sprintf('%s/timeseries/%s/layers/%d/annotations', obj.session.host,...
            obj.timeSeriesId, obj.layerId);
        params = obj.load_annotation_params(varargin{:});
        resp = obj.session.request.get(uri, params);
        resp = resp.annotations.results;
        
        % handle response
        annotation = struct();
        for i = 1 : length(resp)
            if i == 1
                annotation = BFTimeseriesAnnotation.createFromResponse(resp{i}, ...
                    obj.session);
            else
                annotation = [BFTimeseriesAnnotation.createFromResponse(resp{i},...
                    obj.session), annotation];
            end
        end
        out = annotation;
    end
    
    function delete_annotation(obj, annotationId)
        % DELETE_ANNOTATION Removes the specified annotation
        %
        % Args:
        %       ID (str): ID of the annotation to delete
        %
        %
        uri = sprintf('%s%s%s%s%d%s%s', obj.session.host, 'timeseries/', ...
            obj.timeSeriesId, '/layers/', obj.layerId, '/annotations/', annotationId);
        message = '';
        obj.session.request.delete(uri, message);
    end
    
    function show_annotations(obj, endtime)
        % SHOW_ANNOTATIONS displays all the annotations for a given layer object in the console 
        %
        % Args:
        %       end (int): end time for which to include annotations
        %
        % Examples:
        %
        %               Show all the annotations for the BF layer object ``sz`` that is assocaited to ``ts``, a timeseries object::
        %
        %                     >> sz.show_annotations(ts.endTime);
        %                     Annotations for 'Seizures' layer:
        %                     ID: "4849", Label: "Focal Seizure", Description: "", Start: 1301921822000000, Stop: 1301922421995000"
        %                     ID: "4848", Label: "Generalized seizure", Description: "Secondary Generalization", Start: 1301921822000000, Stop: 1301922422095000"
        %
        %
        l = obj.annotations('end', endtime);
        fprintf('Annotations for "%s" layer:\n', obj.name);
        for i  = 1 : length(l)
            fprintf('ID: "%d", Label: "%s", Description: "%s", Start: %d, Stop: %d"\n', ...
                l(1,i).annotationId, l(1,i).label, l(1,i).description, ...
                l(1,i).startTime, l(1,i).endTime);
        end
    end
    
    function out = annotations2table(obj, endtime)
        % ANNOTATIONS2TABLE stores all of the annotations associated with a
        % layer object in a MATLAB table. The output is a table that
        % looks as follows:
        %
        %         +---------------+-----------------+------------------------+------------+----------+
        %         | ID            | Name            | Description            | Start_Time | End_Time |
        %         +---------------+-----------------+------------------------+------------+----------+
        %         | annotation_id | annotation_name | annotation_description | start_time | end_time |
        %         +---------------+-----------------+------------------------+------------+----------+
        %
        % Args:
        %       end (int): end time for which to include annotations
        %
        % Examples:
        %
        %            Store all the annotations in the "Seizures" layer
        %            (``sz`` object) for ``ts``, a timeseries object::
        %
        %                 >> sz.annotations2table(ts.endTime)
        %
        %                 ans =
        %
        %                   2×5 table
        %
        %                       ID              Name                    Description                Start_Time             End_Time
        %                     ______    _____________________    __________________________    __________________    __________________
        %
        %                     '4853'    'Generalized Seizure'    'secondary generalization'    '1301921827000000'    '1301921832000000'
        %                     '4850'    'Focal Seizure'          ''                            '1301921822000000'    '1301921822500000'
        %
        %
        l = obj.annotations('end', endtime);
        col_names = {'ID', 'Name', 'Description', 'Start_Time', 'End_Time'};
        out_table = cell2table(cell(length(l), length(col_names)));
        out_table.Properties.VariableNames = col_names;
        for i=1:length(l)
            out_table(i,1) = {char(string(l(i).annotationId))};
            out_table(i,2) = {l(i).label};
            out_table(i,3) = {l(i).description};
            out_table(i,4) = {char(string(l(i).startTime))};
            out_table(i,5) = {char(string(l(i).endTime))};
        end
        out = out_table;
    end
     
  end
  
  methods (Access = private)
      
      function out = load_annotation_params(obj, varargin)
          % LOAD_ANNOTATION_PARAMS Parameter parser
          %
          defaultStart = 0;
          defaultEnd = 100000000;
          
          p = inputParser;
          addParameter(p, 'start', defaultStart);
          addParameter(p, 'end', defaultEnd);
          addParameter(p, 'layerName', obj.name);
          
          parse(p,varargin{:})
          
          % format parsed parameters
          j=1;
          params=cell(1,length(p.Parameters)*2);
          for i = 1:length(p.Parameters)
              params{j}=p.Parameters{i};
              params{j+1}=getfield(p.Results, p.Parameters{i});
              j=j+2;
          end        
          out = params;
          
      end
    
  end
  
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets',obj.session.web_host,obj.session.org);
                s = sprintf('  <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',url,class(obj));
            else
                s = '';
            end
        end
    end
  
   methods(Static, Hidden)
       
       function out = createFromResponse(resp, session)
           % CREATEFROMRESPONSE creates the timeseries annotation layer
           % object form a response
           %
           content = resp;
           out = BFTimeseriesAnnotationLayer(session, content.id, ...
               content.name, content.timeSeriesId, content.description);
       end
   end
  
end
