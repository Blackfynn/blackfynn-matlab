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
        dataset = ''        % The dataset that the record belongs to
        propNames = {}      % Cell array with dynamic property names
    end
    
    methods
        function obj = BFRecord(session, id, modelid, dataset)
            %BFRECORD Construct an instance of the BFRECORD Class
            %   Detailed explanation goes here
            
            narginchk(4,4);
            obj = obj@BFBaseNode(session, id);
            
            if nargin
                obj.modelId = modelid;
                obj.dataset = dataset;
            end
        end
        
        function obj = update(obj)
            %UPDATE  Update object on the platform
            %   OBJ = UPDATE(OBJ) synchronizes local changes with the
            %   platform. 
            
            content = cell(1, length(obj.propNames));
            
            for i=1:length(obj.propNames)
                content{i} = struct('name',obj.propNames{i}, 'value',...
                    obj.(obj.propNames{i}));
            end
            
            uri = sprintf('%s/datasets/%s/concepts/%s/instances/%s', ...
                obj.session.concepts_host, obj.dataset.id,obj.modelId,obj.id);
            params = struct('values',[]);
            params.values = content;
            obj.session.request.put(uri, params);
            
            obj.updated = false;
        end
        
        function obj = link(obj, target, relationship)
        end
        
        function out = getRelatedCount(obj)
            % GETRELATEDCOUNT Returns relationship info for object
            %   INFO = GETRELATEDCOUNT(OBJ) returns an structure array with
            %   all models that are related to the current object and the
            %   number of records that are related to this object for each
            %   of the models.
            
            uri = sprintf('%s/datasets/%s/concepts/%s/related', ...
                obj.session.concepts_host, obj.dataset.id,obj.modelId);
            params = {};
            out = obj.session.request.get(uri, params);
        end
        
        function [relatedRecords, info] = getRelated(obj, model, limit, offset)
            % GETRELATED Returns an array of related records
            %   RECORDS = GETRELATED(OBJ) returns the first 100 records
            %   of each type of model that is related to the current
            %   object.
            %
            %   [RECORDS, INFO] = GETRELATED(OBJ) returns an INFO
            %   structure in addition to the records that contains the
            %   total number of records that are related to the current
            %   record per model, and the number of returned records. 
            %
            %   [RECORDS, INFO] = GETRELATED(OBJ, MODEL) Returns the
            %   first 100 records for the provided MODEL where MODEL can be
            %   an object of class BFMODEL, or a string with the name of
            %   the model.
            %
            %   [RECORDS, INFO] = GETRELATED(OBJ, MODEL, LIMIT, OFFSET)
            %   returns n number of records as specified by the LIMIT and
            %   OFFSET parameters. LIMIT is a number indicating the
            %   maximum number of records that should be returned, and
            %   OFFSET is the index of the first object that should be
            %   returned. 
            %
            %   For example:
            %       [RECORDS, INFO] = GETRELATED(obj, 'disease', 100, 1)
            
            allModels = true;
            modelName = '';
            offset_ = 0;
            limit_ = 100;
            switch nargin
                case 1
                case 2
                    allModels = false;
                    if isa(model,'BFModel')
                        modelName = model.name;
                    else
                        modelName = model;
                    end
                    
                case 4
                    allModels = false;
                    if isa(model,'BFModel')
                        modelName = model.name;
                    else
                        modelName = model;
                    end
                    
                    assert(offset > 0, 'OFFSET is required to be > 0');
                    offset_ = offset - 1; % convert to 0-based indexing
                    
                    assert(limit <= 200, 'LIMIT cannot be greater than 200.');
                    limit_ = limit;
                otherwise
                    error('Incorrect number of input arguments.')
            end
                        
            response = obj.session.conceptsAPI.getRelationCountsForRecord( ...
                obj.dataset.id, obj.modelId, obj.id);
            
            info = struct( ...
                'name',{response.name}, ...
                'totalCount',{response.count},...
                'returnedCount', 0);
            
            modelNames = {obj.dataset.models.name};
            
            relatedRecords = BFRecord.empty();
            if allModels            
                idx = 1;
                for i = 1: length(response)
                    recs = obj.session.conceptsAPI.getRelated(...
                        obj.dataset.id, obj.modelId, obj.id, response(i).name);

                    % Set info
                    info(i).returnedCount = length(recs);

                    % Get ModelId
                    targetModelId = obj.dataset.models(strcmp(recs{1}{2}.type,...
                        modelNames)).id;

                    % Parse response
                    for j = 1: length(recs)
                        relatedRecords(idx) = BFRecord.createFromResponse(...
                            recs{j}{2}, obj.session, targetModelId, obj.dataset);
                        idx = idx + 1;
                    end

                end
            else
                recs = obj.session.conceptsAPI.getRelated(...
                        obj.dataset.id, obj.modelId, obj.id, modelName, limit_, offset_);
                    
                % Get ModelId
                targetModelId = obj.dataset.models(strcmp(recs{1}{2}.type,...
                    modelNames)).id;
                
                % Set info
                infoNames = {info.name};
                info(strcmp(modelName,infoNames)).returnedCount = length(recs);
                
                % Parse response
                idx = 1;
                for j = 1: length(recs)
                    relatedRecords(idx) = BFRecord.createFromResponse(...
                        recs{j}{2}, obj.session, targetModelId, obj.dataset);
                    idx = idx + 1;
                end

            end

        end
        
        function obj = delete(obj)
            % check all records from same model
            if ~all(strcmp({obj.modelId}, obj(1).modelId))
                sprintf(2, 'All records should belong to the same model.');
                return
            end
            
            % check all records in single dataset
            if ~all(strcmp({obj.dataset.id}, obj(1).dataset.id))
                sprintf(2, 'All records should belong to the same dataset.');
                return
            end
            
            recordIds = {obj.id};
            success = obj(1).session.conceptsAPI.deleteRecords( ...
                obj(1).dataset.id, obj(1).modelId, recordIds);
            
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
                url = sprintf('%s/%s/datasets/%s/explore/%s/%s',obj.session.web_host,obj.session.org,obj.dataset.id,obj.modelId,obj.id);
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
                s = sprintf(' %s(%s) with properties: %s\n',  classNameStr, obj.type, updatedStr);

            end
            
        end
    end
    
    methods (Static, Hidden)
        function out = createFromResponse(resp, session, modelId, dataset)
            %CREATEFROMRESPONSE  Create object from server response
            % args = [session, id, name, display_name,
            %           description, locked, created_at, updated_at ]  
          
            out = BFRecord(session, resp.id, modelId, dataset);
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
                addlistener(out,curProp.name,'PostSet', ...
                    @BFRecord.handlePropEvents);

            end
        end

        function handlePropEvents(src, evnt)
            % Set updated flag to True
            evnt.AffectedObject.updated = true;
            fprintf('upated');
        end
        
    end
end

    