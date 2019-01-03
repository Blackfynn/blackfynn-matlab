classdef BFMainAPI
    
    properties
        session_
        host = 'https://api.blackfynn.io';
        name = 'api';
    end
    
    methods
        function obj = BFMainAPI(session, varargin)
            %BFMAINAPI Construct an instance of this class
            %   Detailed explanation goes here
            
            narginchk(1,2);
            obj.session_ = session;
            
            if nargin == 2
                obj.host = varargin{1};
            end
            
            % Turn off warnings about DELETE method having a body in the
            % request.
            warning('off','MATLAB:http:BodyUnexpectedFor');
            
        end
        
        %% ACCOUNT
        
        function session = getSessionToken(obj, token, secret)

            request = obj.session_.request;
            endPoint = sprintf('%s/account/api/session',obj.host);
            params = struct(...
                'tokenId',token, ...
                'secret',secret ...
                );
            session = request.post(endPoint, params);
            

        end
        
        %% USER
        
        function user = getUser(obj)
            
            endPoint = sprintf('%s/user/',obj.host);
            user = obj.session_.request.get(endPoint,{});
            
        end
        
        %% DATASETS
        
        function datasets = getDatasets(obj)
            
            % API does not provide info for items within a dataset.
            endPoint = sprintf('%s/datasets',obj.host);
            params = {};
            response = obj.session_.request.get(endPoint, params);
            datasets = BFBaseDataNode.createFromResponse(response, obj.session_);
            
            % Sort datasets by creation date
            cdates = [datasets.createdAt_];
            [~,i] = sort(cdates);
            datasets = datasets(i);
        end
        
        function resp = getDataset(obj, datasetId)
            
            % API provides full info about dataset including children.
            endPoint = sprintf('%s/datasets/%s',obj.host, datasetId);
            params = {} ;
            resp = obj.session_.request.get(endPoint, params);
        end
        
        function resp = createDataset(obj, name, description)
            endPoint = sprintf('%s/datasets',obj.host);
            
            params = struct(...
                'name', name,...
                'description', description,...
                'properties', []);
            
            resp = obj.session_.request.post(endPoint, params);
               
        end
        
        function success = updateDataset(obj, datasetId, name, description)
            endPoint = sprintf('%s/datasets/%s', obj.session_.host, datasetId);
            params = struct(...
                'name', name,...
                'description', description);
            success = obj.session_.request.put(endPoint, params);
        end
        
        function success = deleteDataset(obj, datasetId)
            
            endPoint = sprintf('%s/datasets/%s', obj.host, datasetId);
            params = {} ;
            success = obj.session_.request.delete(endPoint, params);
        end

        %% ORGANIZATIONS
        
        function organizations = getOrganizations(obj)
            params = {'includeAdmins' 'false'};
            endPoint = sprintf('%s/organizations',obj.host);
            
            request = obj.session_.request;
            organizations = request.get(endPoint, params);
        end
        
        %% PACKAGES
        
        function resp = getPackage(obj, id, includeSources, includeAncestors)
            
            boolStr = {'false' 'true'};
            endPoint = sprintf('%s/packages/%s',obj.host,id);
            params = {'includeAncestors' boolStr{includeAncestors +1} 'include' boolStr{includeSources +1}};
            resp = obj.session_.request.get(endPoint, params);
        end
               
        function resp = createFolder(obj, datasetId, parentId, name)
            
            endPoint = sprintf('%s/packages',obj.host);
            
            params = struct('name', name,...
                        'packageType', 'Collection',...
                        'dataset', datasetId);
            if parentId
                params.parent = parentId;
            end

            resp = obj.session_.request.post(endPoint, params);
        end
               
        function success = updatePackage(obj, packageId, name, state, packageType)
            endPoint = sprintf('%s/packages/%s', obj.host, packageId);
            params = struct(...
                  'name', name,...
                  'state', state,...
                  'packageType', packageType);
            success = obj.session_.request.put(endPoint, params);
        end
        
        %% DATA
        
        function success = deletePackages(obj, ids)
            endPoint = sprintf('%s/data/delete',obj.host);
            
            message = struct(...
                'things', []);
            
            message.things = ids;
            resp = obj.session_.request.post(endPoint, message);
            
            success = true;
            if ~isempty(resp.success)
                fprintf('\nSuccess removing the following items:\n')
                for i = 1 : length(resp.success)
                    fprintf('%d. %s, item was successfully deleted\n',...
                        i, char(resp.success(i)))
                end
            end
            
            if ~isempty(resp.failures)
            
                fprintf('\n')
                warning('Not all items were deleted')
                fprintf('\nFailed to remove the following items:\n')
                for i = 1 : length(resp.failures)
                    fprintf('%d. %s, item was not deleted\n',...
                        i, resp.failures(i).error)
                end
            end     
            
        end
        
        function success = move(obj, thingIds, destinationId)
            
            endPoint = sprintf('%s/data/move',obj.host);
            message = struct(...
            'things', [],...
            'destination', destinationId);

            message.things = thingIds;
            resp = obj.session_.request.post(endPoint, message);
        
            success = true;
            if ~isempty(resp.success)
                fprintf('\nSuccess moving the following items:\n')
                for i = 1 : length(resp.success)
                    fprintf('%d. %s, item was successfully moved\n',...
                        i, char(resp.success(i)))
                end
            end
            
            if ~isempty(resp.failures)
            
                fprintf('\n')
                warning('Not all items were moved')
                fprintf('\nFailed to move the following items:\n')
                for i = 1 : length(resp.failures)
                    fprintf('%d. %s, item was not moved\n',...
                        i, resp.failures(i).error)
                end
            end     
            
        end
        
        %% TABULAR
        
        function resp = getTabularData(obj, packageId, varargin)
            
            %load params
            defaultLimit = 1000;
            defaultOffset = '';
            defaultOrder = '';
            defaultDirection = 'ASC';
            expectedDirection = {'ASC', 'DESC'};
            
            p = inputParser;
            addParameter(p,'limit', defaultLimit);
            addParameter(p, 'offset', defaultOffset);
            addParameter(p, 'orderBy', defaultOrder);
            addParameter(p, 'orderDirection', defaultDirection,...
                @(x) any(validatestring(x,expectedDirection)));
            parse(p,varargin{:});
            
            j=1;
            params=cell(1,length(p.Parameters)*2);
            for i = 1:length(p.Parameters)
                params{j}=p.Parameters{i};
                params{j+1}=getfield(p.Results, p.Parameters{i});
                j=j+2;
            end
            
            
            endPoint = sprintf('%s/tabular/%s', obj.host,packageId);
            resp = obj.session_.request.get(endPoint, params);
        end
        
        %% TIMESERIES
        
        function resp = getAnnotationLayers(obj,packageId)
            endPoint = sprintf('%s/timeseries/%s/layers',obj.host,packageId);
            params = {};
            resp = obj.session_.request.get(endPoint, params);
        end
        
        function resp = createAnnotationLayer(obj, packageId, name, description)
            endPoint = sprintf('%s/timeseries/%s/layers', obj.host, packageId);
            message = struct('name', name, 'description', description);
            resp = obj.session_.request.post(endPoint, message);
        end
        
        function resp = deleteAnnotationLayer(obj, packageId, layerId)
            endPoint = sprintf('%s/timeseries/%s/layers/%d', obj.host, ...
            packageId, layerId);
            message = '';
            resp = obj.session_.request.delete(endPoint, message);
        end
        
        function resp = getTimeseriesChannels(obj, packageId)
            endPoint = sprintf('%s/timeseries/%s/channels', obj.host, packageId);
            params = {};
            resp = obj.session_.request.get(endPoint, params);
        end
        
        function resp = getTimeseriesChannel(obj, packageId, channelId)
            endPoint = sprintf('%s/timeseries/%s/channels/%s',obj.host, packageId, channelId);
            params = {};
            resp = obj.session_.request.get(endPoint, params);
        end
        
        function resp = createTimeseriesAnnotation(obj, packageId, layerId, name, label, channelIds, startTime, endTime, description)
            
            endPoint = sprintf('%s/timeseries/%s/layers/%d/annotations', obj.host, packageId, layerId);
            
            % create params
            p = inputParser;
            addParameter(p, 'name', name);
            addParameter(p, 'label', label);
            addParameter(p, 'start', startTime);
            addParameter(p, 'end', endTime);
            addParameter(p, 'layer_id', layer_id);
            addParameter(p, 'channelIds', channelIds);
            addParameter(p, 'description', description);

            % format parsed parameters
            results_cell = struct2cell(p.Results);    
            params=struct();
            for i = 1:length(p.Parameters)
               params.(p.Parameters{i})=results_cell{i};
            end
            
            % make request
            resp = obj.session_.request.post(endPoint, message);
            
        end
        
        function resp = getAnnotations(obj, packageId, layerId, start, stop, offset, limit)
            
            uri = sprintf('%s/timeseries/%s/layers/%d/annotations', obj.session_.host,...
            packageId, layerId);
        
            params = {
                'start'; start;  ...
                'end'; stop;  ...
                'includeLinks'; 'false';  ...
                'limit'; limit;  ...
                'offset'; offset};
            resp = obj.session_.request.get(uri, params);
            resp = resp.annotations;
            
        end
        
    end
end

