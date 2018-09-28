classdef BFMainAPI
    %BFMAINAPI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        session
        host = 'https://api.blackfynn.io';
        name = 'api';
    end
    
    methods
        function obj = BFMainAPI(session, varargin)
            %BFMAINAPI Construct an instance of this class
            %   Detailed explanation goes here
            
            narginchk(1,2);
            obj.session = session;
            
            if nargin == 2
                obj.host = varargin{1};
            end
            
            % Turn off warnings about DELETE method having a body in the
            % request.
            warning('off','MATLAB:http:BodyUnexpectedFor');
            
        end
        
        %% ACCOUNT
        
        function session = getSessionToken(obj, token, secret)

            request = obj.session.request;
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
            user = obj.session.request.get(endPoint,{});
            
        end
        
        %% DATASETS
        
        function datasets = getDatasets(obj)
            
            % API does not provide info for items within a dataset.
            endPoint = sprintf('%s/datasets',obj.host);
            params = {};
            response = obj.session.request.get(endPoint, params);
            datasets = BFBaseDataNode.createFromResponse(response, obj.session);
        end
        
        function resp = getDataset(obj, id)
            
            % API provides full info about dataset including children.
            endPoint = sprintf('%s/datasets/%s',obj.host,id);
            params = {} ;
            resp = obj.session.request.get(endPoint, params);
        end
        
        function dataset = createDataset(obj, name, description)
            endPoint = sprintf('%s/datasets',obj.host);
            
            params = struct(...
                'name', name,...
                'description', description,...
                'properties', []);
            
            resp = obj.session.request.post(endPoint, params);
            dataset = BFBaseDataNode.createFromResponse(resp, obj.session);

            
        end
        
        function success = updateDataset(obj, datasetId, name, description)
            endPoint = sprintf('%s/datasets/%s', obj.session.host, datasetId);
            params = struct(...
                'name', name,...
                'description', description,...
                'properties', []);
            success = obj.session.request.put(endPoint, params);
        end

        %% ORGANIZATIONS
        
        function organizations = getOrganizations(obj)
            params = {'includeAdmins' 'false'};
            endPoint = sprintf('%s/organizations',obj.host);
            
            request = obj.session.request;
            organizations = request.get(endPoint, params);
        end
        
        %% PACKAGES
        
        function resp = getPackage(obj, id, includeSources, includeAncestors)
            
            boolStr = {'false' 'true'};
            endPoint = sprintf('%s/packages/%s',obj.host,id);
            params = {'includeAncestors' boolStr{includeAncestors +1} 'include' boolStr{includeSources +1}};
            resp = obj.session.request.get(endPoint, params);
        end
               
        function resp = createFolder(obj, datasetId, parentId, name)
            
            endPoint = sprintf('%s/packages',obj.host);
            
            params = struct('name', name,...
                        'packageType', 'Collection',...
                        'dataset', datasetId);
            if parentId
                params.parent = parentId;
            end

            resp = obj.session.request.post(endPoint, params);
        end
               
        function success = updatePackage(obj, packageId, name, state, packageType)
            endPoint = sprintf('%s/packages/%s', obj.host, packageId);
            params = struct(...
                  'name', name,...
                  'state', state,...
                  'packageType', packageType);
            success = obj.session.request.put(endPoint, params);
        end
        
        %% DATA
        function success = deletePackages(obj, ids)
            endPoint = sprintf('%s/data/delete',obj.host);
            
            message = struct(...
                'things', []);
            
            message.things = ids;
            resp = obj.session.request.post(endPoint, message);
            
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
            resp = obj.session.request.post(endPoint, message);
        
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
        
        function resp = getTabularData(packageId, varargin)
            
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
            resp = obj.session.request.get(endPoint, params);
        end
        
    end
end

