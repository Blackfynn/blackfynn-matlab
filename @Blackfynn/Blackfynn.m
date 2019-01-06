classdef (Sealed) Blackfynn < BFBaseNode
    % BLACKFYNN Main class for interacting with Blackfynn platform.
    %   OBJ = BLACKFYN() opens a Blackfynn session with your default
    %   profile.
    %   OBJ = BLACKFYNN('profile') opens a Blackfynn session with a
    %   specific profile as defined by the Blackfynn configuration.
    %
    %   BLACKFYNN.SETUP() creates a configuration file for the client
    %
    %   BLACKFYNN.PROFILES() shows a list of profiles that have been setup.    
    
    properties(SetAccess = private)
        profile         % User profile of the active session
        datasets        % Datasets available within this session
    end
    
    methods
        function obj = Blackfynn(varargin)                      
            % BLACKFYNN Main class for interacting with Blackfynn platform.
            %   OBJ = BLACKFYN() opens a Blackfynn session with your default
            %   profile.
            %   OBJ = BLACKFYNN('profile') opens a Blackfynn session with a
            %   specific profile as defined by the Blackfynn configuration.
            %
            %   BLACKFYNN.SETUP() creates a configuration file for the client
            %
            %   BLACKFYNN.PROFILES() shows a list of profiles that have been
            %   setup.
            %
            %   See also:
            %       Blackfynn.setup, Blackfynn.profiles
            
            narginchk(0,1);
            obj = obj@BFBaseNode('','');
            
            userProfile = '';
            if nargin == 1
                userProfile = varargin{1};
            end
            
            obj.session_ = BFSession();
            obj.session_.request = BFRequest();
            
            
            
            % Check version if user is using an installed toolbox.
            toolboxes = matlab.addons.toolbox.installedToolboxes;
            if ~isempty(toolboxes) 
                bfIndex = strcmp({toolboxes.Name},'blackfynn');

                if any(bfIndex)
                    version = split(toolboxes(bfIndex).Version,'.');
                    latestVersion = split(strip(webread('http://data.blackfynn.io/public-downloads/blackfynn-matlab/latest/matlab_version.txt')),'.');
                    if version{1}~=latestVersion{1} || version{2}~=latestVersion{2}
                        url = 'http://data.blackfynn.io/public-downloads/blackfynn-matlab/latest/blackfynn.mltbx';
                        fprintf(2, '\nThere is a newer version of the Blackfynn toolbox available (%s).\nPlease download the <a href = "%s">latest version</a> and update the toolbox.\n',latestVersion, url);
                    end
                end    
            end
                
            % Get username and pwd from file
            home = Blackfynn.getHome;
            bfdir = '.blackfynn';
            fname = 'config.ini';
            dirpath = fullfile(home, bfdir);
            fullpath = fullfile(dirpath, fname);
            
            if exist(dirpath, 'dir')
                config = IniConfig();
                status = config.ReadFile(fullpath);
                
                if ~status
                    error('Unable to read config file.');
                end
                
                sections = config.GetSections;
                if isempty(userProfile)
                    defaultIdx = strcmp('default_profile',config.GetKeys('global'));
                    globalValues = config.GetValues('global');
                    userProfile = globalValues{defaultIdx};
                else
                    if ~any(strcmp(sections, ['[' userProfile ']']))
                        error('UserProfile does not exist, use BLACKFYNN.profiles to see all available profiles.');
                    end
                end
                
                keyValues = config.GetValues(userProfile, ...
                    {'api_token' 'api_secret' 'api_host' 'streaming_api_host' 'concepts_api_host' 'web_host'});
                
                % if the streaming_api and api_host fields are specified in the
                % config file, use their values.
                defaultHosts = BFSession.getDefaultHosts();
                if isempty(keyValues{4}) == 0
                   obj.session_.streaming_host = keyValues{4}; 
                else
                   obj.session_.streaming_host = defaultHosts.streamingHost; 
                end
                if isempty(keyValues{3}) == 0
                   obj.session_.mainAPI = BFMainAPI(obj.session_, keyValues{3}); 
                   obj.session_.host = keyValues{3};
                else
                   obj.session_.mainAPI = BFMainAPI(obj.session_);
                   obj.session_.host = defaultHosts.host; 
                end
                if isempty(keyValues{5}) == 0
                   obj.session_.conceptsAPI = BFConceptsAPI(obj.session_, keyValues{5});
                   obj.session_.concepts_host = keyValues{5};
                else
                   obj.session_.conceptsAPI = BFConceptsAPI(obj.session_);
                   obj.session_.concepts_host = defaultHosts.conceptsHost; 
                end
                if isempty(keyValues{6}) == 0
                   obj.session_.web_host = keyValues{6};
                else
                   obj.session_.web_host = defaultHosts.webHost; 
                end
                
                
            else
                error('Username and password not found: Use setup method');
            end
   
            resp = obj.session_.mainAPI.getSessionToken(keyValues{1}, keyValues{2});
            
            % Login agent
            obj.session_.agent = BFAgent();
            obj.session_.agent.login(userProfile);

            % Set API key
            obj.session_.api_key = resp.session_token;
            obj.session_.org = resp.organization;
            obj.session_.setAPIKey(resp.session_token);
            
            % Get User and organization info
            user = obj.session_.mainAPI.getUser();
            
            % Get Organizations
            obj.profile = struct(...
                'id', user.id,...
                'email', user.email,...
                'firstName',user.firstName,...
                'lastName',user.lastName,...
                'organization',user.preferredOrganization,...
                'credential',user.credential);
            
            % get datasets
            obj.datasets = obj.session_.mainAPI.getDatasets();
        end
        
        function dataset = createDataset(obj, name, varargin)   
            % CREATEDATASET Creates a new dataset in organization
            %   DS = CREATEDATASET(OBJ, 'Name') creates a new dataset in
            %   the current organization with the provided 'Name'. The
            %   newly created dataset is returned from the method.
            %   DS = CREATEDATASET(OBJ, 'Name', 'Description') adds a
            %   description to the newly created dataset.
            %
            %
            %   Example:
            %
            %       bf = Blackfynn() 
            %       ds = bf.createdataset('new dataset', 'demo dataset')
            %
            %   See also:
            %       Blackfynn
            
            description = '';
            if nargin > 2
                description = varargin{1};
            end

            resp = obj.session_.mainAPI.createDataset( name, description);
            dataset = BFBaseDataNode.createFromResponse(resp, obj.session_);
            obj.datasets = [obj.datasets dataset];

        end
        
        function success = deleteDataset(obj, dataset, varargin)
            %DELETEDATASET  Delete a dataset from the platform
            %   SUCCESS = DELETEDATASET(OBJ, DATASET) deletes a dataset
            %   and all of its data from the platform. The user will be
            %   asked to confirm this action.
            %   SUCCESS = DELETEDATASET(OBJ, DATASET, 'force', true)
            %   deletes a dataset and all of its data from the platform
            %   without asking the user to confirm this action.
            %
            %   NOTE: This action is permanent and the data cannot be
            %   recovered after deleting a dataset!
    
            forceDelete = false;
            
            % Check for force
            if nargin > 2
                if strcmp(varargin{1}, 'force') && varargin{2}
                    forceDelete = true;
                end
            end
            
            % Check dataset in Org
            remIdx = find(obj.datasets == dataset, 1);
            
            % Ask user for confirmation by default
            if ~forceDelete
                url = sprintf('%s/%s/datasets/%s',obj.session_.web_host,obj.session_.org,dataset.id_);
                fprintf(2,['\nYou are about to delete the dataset: <a href = "%s">%s</a>' ...
                    '\nThis will delete all data in this dataset from the Blackfynn platform.\n\n'...
                    'Please type the name of the dataset to continue:\n'],url, dataset.name);
      
                in = input('Delete Dataset: ','s');
                
                if ~strcmp(in, dataset.name)
                    error('Name does not match - canceling delete.')
                end
            end
            
            
            resp = obj.session_.mainAPI.deleteDataset(dataset.id_);
            sc = resp.StatusCode;
            if sc == matlab.net.http.StatusCode.OK
                % remove from datasets in Blackfynn object.
                obj.datasets(remIdx) = [];
                delete(dataset);
                success = true;
            else
                error('There was an error deleting the dataset.')
            end            
            
        end

        function organizations = organizations(obj)             
            % ORGANIZATIONS  Returns all organizations for the user.
            %   OUT = ORGANIZATIONS(OBJ) returns all organizations that a
            %   user belongs to.
            %
            %   Note:
            %     The user will need to create a separate API token for
            %     each organization in order to access the data through the
            %     API. A session can only interact with data from a single
            %     organization.
            %
            %   Example:
            %
            %      BF = BLACKFYNN('profile_name')
            %      BF.ORGANIZATIONS()
            %
            %      ans = 
            %
            %          Name                                 Id                          
            %       ___________    ______________________________________
            %       'Blackfynn'    'N:organization:c9055555-3333-4444-...
            
            response = obj.session_.mainAPI.getOrganizations();            
            len_org=length(response.organizations);
            col_names = {'Name','Id'};
            organizations = cell2table(cell(len_org, length(col_names)));
            organizations.Properties.VariableNames=col_names;
            for i=1:len_org
                organizations(i, 1) = {response.organizations(i).organization.name};
                organizations(i, 2) = {response.organizations(i).organization.id};
            end
        end
        
        function delete(obj, delobjs)                           
            % DELETE Deletes an object from the platform.
            %   DELETE(OBJ, DELOBJS) deletes the objects in the array
            %   DELOBJS. DELOBJS can be a combination of data packages,
            %   and folders. When deleting folders, all child items will
            %   also be deleted.
            %
            %   DELETE(OBJ, DELIDS) deletes the objects with the IDS in the
            %   cell-array of strings DELIDS. DELIDS can refer to a
            %   combination of data packages, and folders. When deleting
            %   folders, all child items will also be deleted.
            %   
            %   Note: datasets cannot be deleted through the Matlab Client.
            %
            %   Example:
            %
            %       BF = Blackfynn()
            %       PKG1 = BF.datasets(1).items(1)
            %       COL1 = BF.datasets(1).items(2)
            %       REM = [PKG1 COL1]
            %
            %       BF.DELETE(REM)
            %
            %   See also:
            %       Blackfynn
            
            
            things = {};
            if iscellstr(delobjs)
                things = delobjs;
            elseif isa(ts,'BFBaseDataNode')
                things{length(delobjs)} = '';
                for i = 1 : length(delobjs)
                    things{i} = delobjs(i).id_;
                end
            else
                error('Incorrect input type');
            end

            things = things(~cellfun('isempty',things));
            obj.delete_items(things);
        end
        
        function out = get(obj, thing)                          
            % GET Returns any object based on its Blackfynn ID.
            %   OBJECT = GET(OBJ, 'id') returns the object associated with
            %   the provided Blackfynn ID. Object ids from datasets,
            %   packages and folders are accepted.
            %
            %   Example:
            %       BF = BLACKFYNN()
            %       PKG = BF.GET('N:package:113335eb-2222-47fc-aa...')
            %
            %   See also:
            %       BLACKFYNN
            
            types = split(thing,':');
            assert(length(types) == 3, 'Incorrect object ID');
            type = types{2};
            
            switch (type)
                case 'dataset'
                    out = obj.getDataset(thing);
                case 'package'
                    out = obj.getPackage(thing);
                    
                case 'collection'
                    out = obj.getCollection(thing);
                    
                otherwise
                    fprintf(2, 'Incorrect object ID');
            end
        end
        
        function success = upload(obj, dataset, path, varargin) 
            %UPLOAD  Upload files to the Blackfynn platform
            %   SUCCESS = UPLOAD(OBJ, DATASET, 'path') uploads the contents
            %   from the folder specified in 'path' to the dataset
            %   specified in DATASET. 
            %
            %   For example:
            %       BF = Blackfynn();
            %       SUCCESS = BF.upload(BF.datasets(1), '~/Desktop')
            
            if ~exist(path,'dir')
                error('Provided PATH is not a folder');
            end
            
            success = obj.session_.agent.upload(dataset.id_, path);
        end
        
        function out = listDatasets(obj)                        
            %LISTDATASETS  Displays a list of datasets
            %   OUT = LISTDATASETS(OBJ) returns a table of the dataset
            %   names and Blackfynn IDs in a Matlab table. This can be used
            %   to quickly visualize the available datasets in the
            %   organization.
            
            idx = 1:length(obj.datasets);
            idx = idx';
            name = {obj.datasets.name}';
            id = {obj.datasets.id_}';
            
            out = table(idx,name,id);            
        end
        
        function dataset = getDatasetByName(obj, name)
            % GETDATASETBYNAME returns dataset for given name
            %   DATASET = GETDATASETBYNAME(OBJ, 'name') returns the dataset
            %   with the specified 'name'. If no dataset exists with the
            %   provided name, an empty BFDATASET object is returned.
            
            dsNames = {obj.datasets.name};
            dataset = obj.datasets(strcmp(name, dsNames));
            
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
    
    methods (Hidden, Access = {?BFBaseNode})
        
        function out = getDataset(obj, id)                      
            % GETDATASET  Returns single dataset
            % OUT = GETDATASET(OBJ, 'id') returns a single dataset based on the
            % provided 'id'
            
            resp = obj.session_.mainAPI.getDataset(id);
            out = BFBaseDataNode.createFromResponse(resp, obj.session_);
        end
        
        function out = getPackage(obj, id)                      
            % GET_PACKAGE  Returns single package
            % OUT = GET_PACKAGE(OBJ, 'id') returns a single package based on the
            % provided 'id'
            %
            resp = obj.session_.mainAPI.getPackage(id, false, false);
            out = BFBaseDataNode.createFromResponse(resp, obj.session_);
        end
        
        function out = getCollection(obj, id)                   
            % GET_PACKAGE  Returns collection
            % OUT = GET_PACKAGE(OBJ, 'id') returns a single package based on the
            % provided 'id'
            %
            resp = obj.session_.mainAPI.getPackage(id, true, false);
            out = BFBaseDataNode.createFromResponse(resp, obj.session_);
        end
        
        function success = delete_items(obj, thingIds)          
            success = obj.session_.mainAPI.delete_packages(thingIds);
        end
    end
    
    methods(Static, Hidden)                                 
        function home = getHome()                               
            % GETHOME gets home directory, and BF config
            % path for the OS in use.
            
            if ismac || isunix
                home = getenv('HOME');
            elseif ispc
                home = getenv('USERPROFILE');
            else
                error('This OS is not yet supported');
            end
            
        end
    end
    
    methods(Static)
        function out = profiles()                               
            %PROFILES  Returns all Blackfynn configuration profiles.
            %   PROFILES() Static class-method that shows a list of all
            %   Blackfynn profiles.
            %
            %   P = PROFILES() returns a cell array of strings with the
            %   names of available profiles.
            %
            %   See also:
            %       Blackfynn, Blackfynn.setup
            
            home = Blackfynn.getHome;
            bfdir = '.blackfynn';
            fname = 'config.ini';
            dirpath = fullfile(home, bfdir);
            fullpath = fullfile(dirpath, fname);
            
            % get home directory to set profile
            if exist(dirpath, 'dir')
                config = IniConfig();
                config.ReadFile(fullpath);
                
                sections = config.GetSections;                
                if nargout
                    out = cell(length(sections),1);
                    for i=1: length(out)
                        out{i} = sections{i}(2:end-1);
                    end
                    return;
                else
                    for i=1: length(sections)
                        display(sections{i});
                    end
                end                
            else
                fprintf('No profiles created, use BLACKFYNN.SETUP to create profile');
            end
        end
        
        function setup()                                        
            %SETUP  Setup a profile for the Blackfynn client.
            %   SETUP() Static method to create a profile that contains an
            %   API token and secret to use as credentials for using the
            %   Blackfynn MATLAB client.
            %            
            %   See also:
            %       Blackfynn.profiles
            
            home = Blackfynn.getHome;
            bfdir = '.blackfynn';
            fname = 'config.ini';
            dirpath = fullfile(home, bfdir);
            fullpath = fullfile(dirpath, fname);
            
            filename = fullpath;
            
            profile = input('Enter a profile name: ','s');
            token = input('Provide API key: ','s');
            secret = input('Provide API secret: ','s');
            
            % Write Config file
            if ~exist(dirpath,'dir')
                mkdir(dirpath);
            end
            
            config = IniConfig();
            
            if exist(filename, 'file')
                conf_file = regexp( fileread(filename), '\n', 'split');
                def_opt = input(...
                    'Do you want to set this as your default profile? (y/n)', 's');

                if strcmp(def_opt(1), 'y')
                    if strcmp(conf_file{1}, '[global]')
                        conf_file{2} = sprintf('default_profile = %s', profile);
                        f = fopen(filename, 'w');
                        fprintf(f, '%s\n', conf_file{:});
                        fclose(f);
                        fprintf('\nThe profile [%s] was set as default\n\n', profile);
                    end
                end
                
            else
                config.AddSections({'global' profile});
                config.AddKeys('global', {'default_profile'},...
                    {profile});               
            end
            
            config.AddSections({profile});
            config.AddKeys(profile,{'api_token' 'api_secret'}, ...
                {token secret});
            config.WriteFile(filename);           
        end
        
        function gotoSite(url)
            %GOTOSITE  Opens the Blackfynn platform in an external browser.
            web(url,'-browser');
        end
       
    end
    
end
