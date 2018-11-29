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
    tsObj           % Timeseries package for layer
  end
  
  methods
    function obj = BFTimeseriesAnnotationLayer(session, id, name, tsObj, description)
        % BFTIMESERIESANNOTATIONLAYER Constructor of
        % BFTIMESERIESANNOTATIONLAYER class.
        
         obj = obj@BFBaseNode(session, id);
         obj.name = name;
         obj.tsObj = tsObj;
         obj.description = description;
    end
    
    function annotations = getAnnotations(obj, varargin)
        % GETANNOTATIONS Retrieves annotations for layer
        %   ANNS = GETANNOTATIONS(OBJ) returns the first 100 annotations
        %   in the current annotation layer.
        %
        %   ANNS = GETANNOTATIONS(..., 'start', STARTTIME) specifies the
        %   start of the range of the annotations that should be returned
        %   as an offset from the start of the timeseries package in
        %   microseconds.
        %
        %   ANNS = GETANNOTATIONS(..., 'stop', STOPTIME) specifies the end
        %   of the range of the annotations that should be returned
        %   as an offset from the start of the timeseries package in
        %   microseconds.
        %
        %   ANNS = GETANNOTATIONS(..., 'offset', OFFSET) specifies an
        %   integer number of annotations that should be skipped before
        %   returning the first annotation.
        %
        %   ANNS = GETANNOTATIONS(..., 'limit', LIMIT) sets a limit to the
        %   number of annotations that will be returned in a single call
        %   (default=100).
        %
        %   For example:
        %
        %       anns = layer.GETANNOTATIONS('offset',0, 'limit', 50) 
        %       -- returns first 50 annotations in layer --
        %
        %       anns = layer.GETANNOTATIONS('offset',100, 'limit', 100)
        %       -- returns annotations 101-200 in layer
        %

        assert(mod(length(varargin),2)==0,'Incorrect number of input arguments');
        
        rangeStart = obj.tsObj.startTime;
        rangeEnd = obj.tsObj.endTime;
        rangeOffset = 0;
        rangeLimit = 100;
        
        if nargin > 1
            for i=1:2:length(varargin)
                switch varargin{i}
                    case 'start'
                        rangeStart = varargin{i+1};
                    case 'end'
                        rangeEnd = varargin{i+1};
                    case 'limit'
                        rangeLimit = varargin{i+1};
                    case 'offset'
                        rangeOffset = varargin{i+1};
                    otherwise
                        error('Incorrect input argument');
                end
            end
        end
            
        resp = obj.session_.mainAPI.getAnnotations(obj.tsObj.id_, ...
            obj.id_, rangeStart, rangeEnd, rangeOffset, rangeLimit );
        anns = resp.results;

        % handle response
        annotations = BFTimeseriesAnnotation.empty(length(anns),0);
        for i = 1 : length(anns)
            annotations(i) = BFTimeseriesAnnotation.createFromResponse(...
                anns(i), obj.session_);
        end
    end
    
    function delete_annotation(obj, annotationId)
        % DELETE_ANNOTATION Removes the specified annotation
        %
        % Args:
        %       ID (str): ID of the annotation to delete
        %
        %
        uri = sprintf('%s%s%s%s%d%s%s', obj.session_.host, 'timeseries/', ...
            obj.timeSeriesId, '/layers/', obj.layerId, '/annotations/', annotationId);
        message = '';
        obj.session_.request.delete(uri, message);
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
    
    function out = listAnnotations(obj, endtime)
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
          
          parse(p, varargin{:})
          
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
                url = sprintf('%s/%s/datasets',obj.session_.web_host,obj.session_.org);
                s = sprintf('  <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s.empty)">Methods</a>',url,class(obj));
            else
                s = '';
            end
        end
    end
  
   methods(Static, Hidden)
       
       function out = createFromResponse(resp, session, tsObj)
           % CREATEFROMRESPONSE creates the timeseries annotation layer
           % object form a response
           %
           content = resp;
           out = BFTimeseriesAnnotationLayer(session, content.id, ...
               content.name, tsObj, content.description);
           
       end
   end
  
end
