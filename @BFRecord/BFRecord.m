classdef BFRecord < BFBaseNode & dynamicprops
    %BFRECORD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        type
    end
    
    properties (Hidden)
        createdAt
        updatedAt
        createdBy
        updatedBy
        
    end
    
    properties (Access = private)
        updated = false     % Flag to see if record changed
        modelId = ''        % Id for model
        datasetId = ''      % Id for dataset
        propNames = {}      % Cell array with dynamic property names
    end
    
    methods
        function obj = BFRecord(varargin)
            %BFRECORD Construct an instance of this class
            %   Detailed explanation goes here
            
            obj = obj@BFBaseNode(varargin{:});
            
            if nargin
                obj.modelId = varargin{3};
                obj.datasetId = varargin{4};
            end
        end
        
        function obj = update(obj)
            %UPDATE  Update object on the platform
            %   OBJ = UPDATE(OBJ) synchronizes local changes with the
            %   platform. 
            
            content = cell(1, length(obj.propNames));
            
            for i=1:length(obj.propNames)
                content{i} = struct('name',obj.propNames{i}, 'value',obj.(obj.propNames{i}));
            end
            
            uri = sprintf('%s/datasets/%s/concepts/%s/instances/%s', obj.session.concepts_host, obj.datasetId,obj.modelId,obj.id);
            params = struct('values',[]);
            params.values = content;
            obj.session.request.put(uri, params);
            
            obj.updated = false;
        end

    end
    
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/explore/%s/%s',obj.session.web_host,obj.session.org,obj.datasetId,obj.modelId,obj.id);
                if obj.updated
                    s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,url,class(obj));
                else
                    %https://test.blackfynn.io/N:organization:c905919f-56f5-43ae-9c2a-8d5d542c133b/datasets/N:dataset:5a6779a4-e3d8-473f-91d0-0a99f144dc44/explore/d7dda599-686b-4213-8ade-f17866e8fc9c/f4b275b4-00dc-edd1-b1b7-1ff362569de3
                    s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>,<a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,url,class(obj));
                end
            else
                s = '';
            end
        end
        function s = getHeader(obj)
            if ~isscalar(obj)
                s = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                classNameStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                updatedStr = '';
                if obj.updated
                    updatedStr = '*local changes*';
                end
                s = sprintf('  %s with properties: %s\n', classNameStr, updatedStr);

            end
            
        end
    end
    
    methods (Static, Hidden)
        function out = createFromResponse(resp, session, modelId, datasetId)
            %CREATEFROMRESPONSE  Create object from server response
            % args = [session, id, name, display_name,
            %           description, locked, created_at, updated_at ]  
          
            out = BFRecord(session, resp.id, modelId, datasetId);
            out.type = resp.type;
            out.id = resp.id;
            out.createdAt = resp.createdAt;
            out.updatedAt = resp.updatedAt;
            out.createdBy = resp.createdBy;
            out.updatedBy = resp.updatedBy;
            out.propNames = cell(1,length(resp.values));
            
            for i=1: length(resp.values)
                curProp = resp.values(i);
                out.propNames{i} = curProp.name;
                p = out.addprop(curProp.name);
                out.(curProp.name) = curProp.value;
                p.SetObservable = true;
                addlistener(out,curProp.name,'PostSet',@BFRecord.handlePropEvents);

            end
        end
        function handlePropEvents(src, evnt)
            % Set updated flag to True
            evnt.AffectedObject.updated = true;
            fprintf('upated');
        end
        
    end
end

    