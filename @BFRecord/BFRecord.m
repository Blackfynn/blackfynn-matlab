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
    %   Restricted property names: {'createdAt_', 'updatedAt_', 'createdBy_',
    %   'updatedBy_', 'session_', 'id_', 'type_', 'updated_', 'model_',
    %   'dataset_'}
        
    properties (Hidden)
        createdBy_   % Indicates who created the record 
        updatedBy_   % Indicates who updated the record 
    end
    
    properties (Access = {?BFConceptsAPI})
        type_                   % Type of the record
        updated_ = false        % Flag to see if record changed
        model_                  % Associated model
        dataset_ = ''           % The dataset that the record belongs to
        updatedLinkedProps_ = {} % Cell array with names of linked Properties that should be updated
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
            
            obj.session_.conceptsAPI.updateRecord(obj);
            
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
        
        function obj = linkFiles(obj, targets)                          
            %LINKFILE Associates a file with the record.
            %   LINKFILE(OBJ, PACKAGES) links one or more packages to the
            %   current record. PACKAGE should be an array of objects of
            %   type BFPackage.
            %
            %   For example:
            %
            %       records = model.getRecords();
            %       files  = dataset.getFiles();
            %       records(1).linkFile(files(1));
            
            for i=1: length(targets)
                obj.session_.conceptsAPI.linkFile(obj.dataset_.id_, {obj.id_}, targets(i).id_);
            end
  
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
            
            relatedRecords = BFRecord.empty();
            info = struct();
            if ~isempty(response)
                info = struct( ...
                    'name',{response.name}, ...
                    'totalCount',{response.count},...
                    'returnedCount', 0);

                modelNames = {obj.dataset_.models.name};

                if allModels            
                    idx = 1;
                    for i = 1: length(response)

                        % Skip files 
                        if strcmp('package', response(i).name)
                            continue
                        end

                        % Get related records
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

        end
        
        function items = getFiles(obj)                                  
            %GETFILES Returns the files associated with the record
            %   ITEMS = GETFILES(OBJ) returns an array of files that are
            %   associated with the current record.
            %
            %   For example:
            %       records = bf.datasets(1).models(1).getRecords()
            %       files = records(1).getFiles()
            
            
            response = obj.session_.conceptsAPI.getFiles( ...
                obj.dataset_.id_, obj.model_.id_, obj.id_);
            
            items = BFBaseDataNode.empty;
            if ~isempty(response)
                items(length(response)) = ...
                            BFCollection('','','','');
                for i=1: length(response)

                    items(i) = BFBaseDataNode.createFromResponse(...
                                response{i}{2}, obj.session_);
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
        
        function out = allvalues(obj, propName)                         
            %ALLVALUES  Return all values for a prop in array of objects
            %   OUT = ALLVALUES(OBJ, 'propName') returns a cell array with
            %   all values of a property in an array of BFRecord objects.
            %
            %   This method provides a workaround for the lack of support
            %   in MATLAB to aggregate values of properties that are
            %   dynamically added to an object. 
            %
            %   Typically, you can access all the values of a property in
            %   an array of objects using the following syntax: 
            %
            %       allProps = {objectArray.propName}
            %
            %   However, this is not available for dynamic properties which
            %   are used in this toolbox. This method provides similar
            %   functionality.
            
            out = cell(1, length(obj));
            for i=1: length(obj)
                out{i} = obj(i).(propName);
            end
            
        end
    end
    
    methods (Access = protected)     
        function out = getLinkedProp(obj, name)                         
            % GETLINKEDPROP  Returns linked Record 
            %   This method fetches a linked record using the API if the
            %   record has not previously been fetched. It does this only
            %   when the property is accessed. This prevents recursively
            %   linked properties between multiple records to behave
            %   incorrectly.
            
            % Get private info about property
            info = obj.([name '_']);
            
            % Return empty object if object is not set.
            if isempty(info)
                out = BFRecord.empty();
                return;
            end
                
            if isempty(info{1})
                % Get object
                info = obj.([name '_']);
                response = obj.session_.conceptsAPI.getRecordInstance(...
                    obj.dataset_.id_, info{2}, info{3});
                
                % Find model
                allModelNames = {obj.dataset_.models.name};
                model = obj.dataset_.models(strcmpi(response.type, allModelNames));   
                out = BFRecord.createFromResponse(response, ...
                    obj.session_, model, obj.dataset_);
                obj.([name '_']){1} = out;
            else
                out = obj.([name '_']){1};
            end
        end
        
        function obj = setLinkedProp(obj, value, prop)                  
            %SETLINKEDPROP  Sets linked property values
            %   OBJ = SETLINKEDPROP(OBJ, VALUE, 'prop') sets the value of
            %   the linked property 'prop' to VALUE. The method checks
            %   whether the model of VALUE is correct and marks the record
            %   as ready to be updated on the platform.
            
            % Find model for current property
            propNames = {obj.model_.props.name};
            toProp = obj.model_.props(strcmp(prop, propNames));
            
            toModel = obj.dataset_.models(...
                strcmp(toProp.toModel,{obj.dataset_.models.id_}));
            
            % Validate provided record
            assert(strcmp(value.model_.id_,toProp.toModel),...
                sprintf('Incorrect model for property.\nExpect model of type: %s', toModel.name));
            
            assert(strcmp(value.dataset_.id_, obj.dataset_.id_),...
                'Incorrect dataset.\nRecords should belong to the same dataset.');

            % Add record and mark for update
            if isempty(obj.(sprintf('%s_', prop)))
                obj.(sprintf('%s_', prop)) = {value toModel.id_ toProp.id_ '' };
            else
                obj.(sprintf('%s_', prop)){1} = value;
            end
            
            obj.updated_ = true;
            alreadyMarked = any(strcmp(prop, obj.updatedLinkedProps_));
            if ~alreadyMarked
                obj.updatedLinkedProps_{length(obj.updatedLinkedProps_)+1} = prop;
            end
        end
        
        function s = getFooter(obj)                                     
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/records/%s/%s',obj.session_.web_host,obj.session_.org,obj.dataset_.id_,obj.model_.id_,obj.id_);
                if obj.updated_
                    s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s.empty)">Methods</a>',obj.id_,url,class(obj));
                else
                    s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>,<a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s.empty)">Methods</a>',obj.id_,url,class(obj));
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
          
            out = BFRecord(session, resp.id, model, dataset);
            out.type_ = resp.type;
            out.id_ = resp.id;
            out.setDates(resp.createdAt, resp.updatedAt);
            out.createdBy_ = resp.createdBy;
            out.updatedBy_ = resp.updatedBy;
            
            for i=1: length(model.props)
                try
                    p = out.addprop(model.props(i).name);
                    p.SetObservable = true;

                    if isa(model.props(i),'BFLinkedModelProperty')
                        % Set Get Method
                        p.GetMethod = @(obj) getLinkedProp(obj, model.props(i).name);
                        p.SetMethod = @(obj,value, name) setLinkedProp(obj, value, model.props(i).name);
                        p2 = out.addprop([model.props(i).name '_']);
                        p2.Hidden = true;
                    end
                catch ME
                    continue
                end
            end
            
            for i=1: length(resp.values)
                curProp = resp.values(i);
                out.(curProp.name) = curProp.value;
                addlistener(out,curProp.name,'PostSet', ...
                    @BFRecord.handlePropEvents);
            end

            % Get Linked Properties
            resp = session.conceptsAPI.getLinkedPropertiesForInstance(dataset.id_, model.id_, resp.id);
            allPropIds = {model.props.id_};
            allPropNames = {model.props.name};
            for i=1: length(resp)
                idx = strcmp(resp(i).schemaLinkedPropertyId, allPropIds);
                out.([allPropNames{idx} '_']) = {BFRecord.empty(1,0) model.props(idx).toModel resp(i).to resp(i).id};
            end
        end

        function handlePropEvents(src, evnt)                            
            % Set updated flag to True
            evnt.AffectedObject.updated_ = true;
            fprintf('upated');
        end
        
    end
end

    