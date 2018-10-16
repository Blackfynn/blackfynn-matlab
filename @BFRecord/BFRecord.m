classdef BFRecord < BFBaseNode & dynamicprops
    %BFRECORD A representation of a metadata record
    %   
    %   Supports local changes.
    
    properties
        type        % Type of the record
    end
    
    properties (Hidden)
        createdAt   % Indicates when record was created
        updatedAt   % Indicates when record was updated
        createdBy   % Indicates who created the record 
        updatedBy   % Indicates who updated the record 
        
    end
    
    properties (Access = private)
        updated = false     % Flag to see if record changed
        modelId = ''        % Id for model
        datasetId = ''      % Id for dataset
        propNames = {}      % Cell array with dynamic property names
    end
    
    methods
        function obj = BFRecord(session, id, modelid, datasetid)
            %BFRECORD Construct an instance of the BFRECORD Class
            %   Detailed explanation goes here
            
            narginchk(4,4);
            obj = obj@BFBaseNode(session, id);
            
            if nargin
                obj.modelId = modelid;
                obj.datasetId = datasetid;
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
        
        function out = getAllRelationships(obj)
            uri = sprintf('%s/datasets/%s/concepts/%s/related', obj.session.concepts_host, obj.datasetId,obj.modelId);
            params = {};
            out = obj.session.request.get(uri, params);
        end
        
        function out = getRelationships(obj)
            uri = sprintf('%s/datasets/%s/concepts/%s/instances/%s/relationCounts', obj.session.concepts_host, obj.datasetId,obj.modelId,obj.id);
            params = {};
            out = obj.session.request.get(uri, params);
        end
        
        function obj = delete(obj)

            % check all records from same model
            if ~all(strcmp({obj.modelId}, obj(1).modelId))
                sprintf(2, 'All records should belong to the same model.');
                return
            end
            
            % check all records in single dataset
            if ~all(strcmp({obj.datasetId}, obj(1).datasetId))
                sprintf(2, 'All records should belong to the same dataset.');
                return
            end
            
            recordIds = {obj.id};
            success = obj(1).session.conceptsAPI.deleteRecords(obj(1).datasetId, obj(1).modelId, recordIds);
            
            % delete matlab objects if platform delete is successfull
            for i=1:length(obj)
                if any(strcmp(obj(i).id, success))
                    delete(obj(i));
                end
            end
            
            % let user know if delete failed 
            if length(success) ~= length(obj)
                diff_l = length(obj)-length(success);
                fprintf(2, '%i our of %i records could not be deleted.\nThis could be because the records no longer exist on the platform.', diff_l, length(obj));
            end
            
            
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

    