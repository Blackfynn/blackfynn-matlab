classdef BFRecord < BFBaseNode & dynamicprops
    %BFRECORD A representation of a metadata record
    %   
    %   Supports local changes.
    %
    %
    %   NOTE: Because of the way that the MATLAB client is implemented,
    %   there are a number of properties names that are restricted as they
    %   are used for internal logic. If you create models on the Blackfynn
    %   platform with property names that match the following list, this
    %   might result in errors in the client.
    %
    %   Restricted property names: {'createdAt', 'updatedAt', 'createdBy',
    %   'updatedBy', 'session_', 'id_', 'type_', 'updated_', 'model_',
    %   'dataset_', 'propNames_'}
        
    properties (Hidden)
        createdAt   % Indicates when record was created
        updatedAt   % Indicates when record was updated
        createdBy   % Indicates who created the record 
        updatedBy   % Indicates who updated the record 
    end
    
    properties (Access = protected)
        type_                   % Type of the record
        updated_ = false        % Flag to see if record changed
        model_                  % Associated model
        dataset_ = ''           % The dataset that the record belongs to
        propNames_ = {}         % Cell array with dynamic property names
    end
    
    methods
        function obj = BFRecord(session, id, model, dataset)            
            %BFRECORD Construct an instance of the BFRECORD Class
            %   Detailed explanation goes here
            
            narginchk(4,4);
            obj = obj@BFBaseNode(session, id);
            
            if nargin
                obj.model_ = model;
                obj.dataset_ = dataset;
            end
        end
        
        function obj = update(obj)                                      
            %UPDATE  Update object on the platform
            %   OBJ = UPDATE(OBJ) synchronizes local changes with the
            %   platform. 
            
            content = cell(1, length(obj.propNames_));
            
            for i=1:length(obj.propNames_)
                content{i} = struct('name',obj.propNames_{i}, 'value',...
                    obj.(obj.propNames_{i}));
            end
            
            uri = sprintf('%s/datasets/%s/concepts/%s/instances/%s', ...
                obj.session_.concepts_host, obj.dataset_.id_,obj.modelId,obj.id_);
            params = struct('values',[]);
            params.values = content;
            obj.session_.request.put(uri, params);
            
            obj.updated_ = false;
        end
        
        function obj = link(obj, targets, relationship)                 
            % LINK create relationships between records
            %   OBJ = LINK(OBJ, TARGETS, 'relationship') creates a
            %   relationship between the current object and the TARGETS
            %   objects. TARGETS can be a single record, or an array of
            %   records of the same model. RELATIONSHIP is string
            %   indicating the relationship-type. 
            %
            %   You will need to first create a relationship between the
            %   models of the record using the BFMODEL.CREATERELATIONSHIP
            %   before you can assign this relationship to records.
            %
            %   For example:
            %       m1 = ds.models(1)
            %       m2 = ds.models(2)
            %       m1.createRelationship(m2, 'contains')
            %
            %       records1 = m1.getRecords()
            %       records2 = m2.getRecords()
            %       record1(1).link(record2(1), 'contains)
            
            % Check al targets are same model
            targetType = targets(1).type_;
            targetModel = targets(1).model_;
            assert(all(strcmp(targetType, {targets.type_})), 'All target records should be of the same type.');
            
            % Find relationship object
            if isa(relationship, 'BFRelationship')
                assert(relationship.from.id_ == obj.model_.id_, 'This relationship is not defined for records of this model.');
                assert(relationship.to.id_ == targets(1).model_.id_, 'This relationship is not defined for records of this model.');
            else
                relNames = {obj.model_.relationships.name};
                relIndeces = strcmp(relationship, relNames);

                if ~any(relIndeces)
                    error('There is no relationship defined with that name. Use the BFMODEL.CREATERELATIONSHIP method to create the relationship');
                else
                    % Check targetType
                    allToModels =  [obj.model_.relationships.to];
                    
                    targetIndeces = strcmp(targetModel.id_, {allToModels.id_});
                    relationship = obj.model_.relationships(relIndeces & targetIndeces);
                    assert(~isempty(relationship), 'Relationship does not exist.');                
                end
            end
            
            response = obj.session_.conceptsAPI.link(obj.dataset_.id_, ...
                relationship.id_, obj.id_, {targets.id_});
            
            assert(length(response) == length(targets), ...
                'Unable to create some of the relationships.');
            
        end
        
        function out = getRelatedCount(obj)                             
            % GETRELATEDCOUNT Returns relationship info for object
            %   INFO = GETRELATEDCOUNT(OBJ) returns an structure array with
            %   all models that are related to the current object and the
            %   number of records that are related to this object for each
            %   of the models.
            
            uri = sprintf('%s/datasets/%s/concepts/%s/related', ...
                obj.session_.concepts_host, obj.dataset_.id_, obj.model_.id_);
            params = {};
            out = obj.session_.request.get(uri, params);
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
                        
            response = obj.session_.conceptsAPI.getRelationCountsForRecord( ...
                obj.dataset_.id_, obj.model_.id_, obj.id_);
            
            info = struct( ...
                'name',{response.name}, ...
                'totalCount',{response.count},...
                'returnedCount', 0);
            
            modelNames = {obj.dataset_.models.name};
            
            relatedRecords = BFRecord.empty();
            if allModels            
                idx = 1;
                for i = 1: length(response)
                    recs = obj.session_.conceptsAPI.getRelated(...
                        obj.dataset_.id_, obj.model_.id_, obj.id_, response(i).name);

                    % Set info
                    info(i).returnedCount = length(recs);

                    % Get ModelId
                    targetModelId = obj.dataset_.models(strcmpi(recs{1}{2}.type,...
                        modelNames)).id_;

                    % Parse response
                    for j = 1: length(recs)
                        relatedRecords(idx) = BFRecord.createFromResponse(...
                            recs{j}{2}, obj.session_, targetModelId, obj.dataset_);
                        idx = idx + 1;
                    end

                end
            else
                recs = obj.session_.conceptsAPI.getRelated(...
                        obj.dataset_.id_, obj.modelId, obj.id_, modelName, limit_, offset_);
                    
                % Get ModelId
                targetModelId = obj.dataset_.models(strcmp(recs{1}{2}.type,...
                    modelNames)).id_;
                
                % Set info
                infoNames = {info.name};
                info(strcmp(modelName,infoNames)).returnedCount = length(recs);
                
                % Parse response
                idx = 1;
                for j = 1: length(recs)
                    relatedRecords(idx) = BFRecord.createFromResponse(...
                        recs{j}{2}, obj.session_, targetModelId, obj.dataset_);
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
            if ~all(strcmp({obj.dataset_.id_}, obj(1).dataset_.id_))
                sprintf(2, 'All records should belong to the same dataset.');
                return
            end
            
            recordIds = {obj.id_};
            success = obj(1).session_.conceptsAPI.deleteRecords( ...
                obj(1).dataset_.id_, obj(1).modelId, recordIds);
            
            % delete matlab objects if platform delete is successfull
            for i=1:length(obj)
                if any(strcmp(obj(i).id_, success))
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
                url = sprintf('%s/%s/datasets/%s/explore/%s/%s',obj.session_.web_host,obj.session_.org,obj.dataset_.id_,obj.model_.id_,obj.id_);
                if obj.updated_
                    s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id_,url,class(obj));
                else
                    s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>,<a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id_,url,class(obj));
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
                if obj.updated_
                    updatedStr = '*local changes*';
                end
                s = sprintf(' %s(%s) with properties: %s\n',  classNameStr, obj.type_, updatedStr);

            end
            
        end
    end
    
    methods (Static, Hidden)
        function out = createFromResponse(resp, session, model, dataset)
            %CREATEFROMRESPONSE  Create object from server response
            % args = [session, id, name, display_name,
            %           description, locked, created_at, updated_at ]  
          
            out = BFRecord(session, resp.id, model, dataset);
            out.type_ = resp.type;
            out.id_ = resp.id;
            out.createdAt = resp.createdAt;
            out.updatedAt = resp.updatedAt;
            out.createdBy = resp.createdBy;
            out.updatedBy = resp.updatedBy;
            out.propNames_ = cell(1,length(resp.values));
            
            
            for i=1: length(resp.values)
                curProp = resp.values(i);
                out.propNames_{i} = curProp.name;
                p = out.addprop(curProp.name);
                out.(curProp.name) = curProp.value;
                p.SetObservable = true;
                addlistener(out,curProp.name,'PostSet', ...
                    @BFRecord.handlePropEvents);

            end
        end

        function handlePropEvents(src, evnt)                            
            % Set updated flag to True
            evnt.AffectedObject.updated_ = true;
            fprintf('upated');
        end
        
    end
end

    