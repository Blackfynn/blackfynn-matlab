classdef (Sealed) Blackfynn < BFBaseNode
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
            
            obj.session = BFSession();
            obj.session.request = BFRequest();
            
            userProfile = '';
            if nargin == 1
                userProfile = varargin{1};
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
                    {'api_token' 'api_secret' 'api_host' 'streaming_api_host'});
                
                % if the streaming_api and api_host fields are specified in the
                % config file, use their values.
                if (isempty(keyValues{4}) == 0) && (isempty(keyValues{3}) == 0)
                    obj.session.host = keyValues{3};
                    obj.session.streaming_host = keyValues{4};
                    
                % if the streaming_api and api_host fields are NOT specified in the
                % config file, set default values.
                else
                    defaultHosts = BFSession.getDefaultHosts();
                    obj.session.host = defaultHosts.host;
                    obj.session.streaming_host = defaultHosts.streamingHost;
                end
                
            else
                error('Username and password not found: Use setup method');
            end
            
            request = obj.session.request;
            
            % Login
            path = '/account/api/session';
            uri = sprintf('%s%s',obj.session.host, path);
            data = struct(...
                'tokenId',keyValues{1}, ...
                'secret',keyValues{2} ...
                );
            resp = request.post(uri, data);
            
            % Set API key
            obj.session.api_key = resp.session_token;
            request.setAPIKey(resp.session_token);
            
            % Get User and organization info
            path = '/user/';
            uri = sprintf('%s%s',obj.session.host, path);
            resp = request.get(uri,{});
            
            % Get Organizations
            obj.profile = struct(...
                'id', resp.id,...
                'email', resp.email,...
                'firstName',resp.firstName,...
                'lastName',resp.lastName,...
                'organization',resp.preferredOrganization,...
                'credential',resp.credential);
            
            % get datasets
            obj.get_datasets();
        end
        
        function out = create_dataset(obj, name, varargin)
            % CREATE_DATASET creates a new dataset under
            % the current organization with the provided ``name``. The newly
            % created dataset is returned from the method.
            %
            % Args:
            %       name (str): name of the new dataset
            %       description (str, optional): description of the dataset
            %
            % Returns:
            %           ``BFDataset``: created dataset.
            %
            % Examples:
            %
            %           Create a new dataset called ``new dataset`` with a
            %           description::
            %
            %               bf = Blackfynn # create client instance
            %               bf.create_dataset('new dataset', 'this is a test dataset')
            %
            %
            uri = sprintf('%s%s',obj.session.host,'datasets/');
            description='';
            
            if nargin > 2
                description = varargin{1};
            end
            
            message = struct(...
                'name', name,...
                'description', description,...
                'properties', []);
            
            resp = obj.session.request.post(uri, message);
            obj.get_datasets();
            out = obj.get(resp.content.id);
            
        end

        function out = get_organizations(obj)
            % GET_ORGANIZATIONS  Returns a table of organizations that the user
            % belongs to.
            %
            % Note:
            %     The user will need to create a separate API token for each
            %     organization in order to access the data through the API. A session
            %     can only interact with data from a single organization.
            %
            % Examples:
            %
            %         Get all the organizations for a user profile::
            %
            %             bf=Blackfynn('profile_name')
            %             bf.get_organizations
            %
            %             ans = 
            %
            %                Name                                 Id                          
            %             ___________    _____________________________________________________
            %             'Blackfynn'    'N:organization:c9055555-3333-4444-9c2a-8d23542c4581'
            %
            uri = 'organizations/';
            params = {'includeAdmins' 'false'};
            endPoint = sprintf('%s%s%s',obj.session.host, uri);
            
            request = obj.session.request;
            resp = request.get(endPoint, params);
            out = obj.handleGetOrganizations(resp);
        end

        function move(obj, dest, varargin)
            %MOVE  Moves objects to a destination collection
            %
            % Args:
            %       destination (str or object): Destination collection object or ID.
            %       things (list of objects): Package objects to move.
            % 
            % Examples:
            %
            %           Move two packages to a collection using the collection's
            %           object::
            %
            %               bf.move(my_collection, pkg1, pkg2)
            %
            %           Move `collection1` into another collection using the
            %           destination ID and the object of ``collection1``::
            %           
            %               bf.move('N:collection:ae8d7f6f-f35a-4029-b78e-5bd1525ade2d', col1)
            %
            % Note:
            %
            %       Data Packages cannot be moved across datasets.
            %
            uri = sprintf('%s%s',obj.session.host,'data/move');
            
            destid = dest;
            if isa(dest,'BFBaseCollection')
                destid = dest.get_id;
            end
            
            thingIds{length(varargin)} = '';
            for i = 1 : length(varargin)
                thingIds{i} = varargin{i}.get_id;
            end
            
            if length(varargin) == 1
                thingIds{2} = '';
            end
            
            message = struct(...
                'things', [],...
                'destination', destid);
            
            message.things = thingIds;
            obj.session.request.post(uri, message);
        end
        
        function delete(obj, varargin)
            %DELETE Deletes an object from the platform.
            %
            % Args:
            %    things (list): ID or object of items to delete.
            %
            % Examples:
            %
            %           In this example ``col`` and ``pkg`` are Collection  and
            %           DataPackage objects respectively.
            %
            %           Remove multiple items through their objects or
            %           IDs::
            %
            %               bf.delete('N:collection:117775eb-2222-47fc-aa8f-7a69ad7a04b2', col, pkg)
            %
            %
            % Note:
            %       For safety, datasets cannot be deleted from the client.
            %
            % Note:
            %       When deleting a ``Collection`` all child items will also
            %       be deleted.
            %
            things{length(varargin)} = '';
            
            for i = 1 : length(varargin)
                switch class(varargin{i})
                    case {'string', 'char'}
                        things{i} = char(varargin{i});
                    case {'BFTimeseries','BFCollection',...
                            'BFDataPackage', 'BFTabular'}
                        things{i} = varargin{i}.get_id;
                    case 'BFDataset'
                        msg=['Datasets cannot be deleted from the client.'...
                            '\n [%s] will not be deleted'];
                        warning(msg, varargin{i}.name)
                end
            end
            things=things(~cellfun('isempty',things));
            obj.delete_items(things)
        end
        
        function out = get(obj, thing)
            %GET  Returns any object based on the Blackfynn ID.
            %
            % Args:
            %       ID (str): ID of the package that is being retrieved.
            %
            % Returns:
            %          Object: object for the package that is
            %          being retrieved
            %
            % Example:
            %
            %           Get a package from the platform and save the object in `pkg`::
            %
            %               pkg =
            %               bf.get('N:package:113335eb-2222-47fc-aa8f-7a90a46a0455');
            %
            types = split(thing,':');
            assert(length(types) == 3, 'Incorrect object ID');
            type = types{2};
            
            switch (type)
                case 'dataset'
                    out = obj.get_dataset(thing);
                case 'package'
                    out = obj.get_package(thing);
                case 'collection'
                    out = obj.get_collection(thing);
                    
                otherwise
                    fprintf(2, 'Incorrect object ID');
            end
        end
    end
    
    methods (Access = protected)
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                s = sprintf('  <a href="matlab: Blackfynn.gotoSite">Webapp</a>, <a href="matlab: methods(%s)">Methods</a>',class(obj));
            else
                s = '';
            end
        end
    end
    
    methods (Hidden, Access = {?BFBaseNode})
        function get_datasets(obj)
            uri = sprintf('%s/%s',obj.session.host, 'datasets');
             params = {'include', '*', 'includeAncestors', 'false',...
                 'api_key', obj.session.request.options.HeaderFields{2}};
            resp = obj.session.request.get(uri,params);
            obj.datasets = BFBaseDataNode.createFromResponse(resp, obj.session);
        end
        
        function out = get_dataset(obj, id)
            % GET_DATASET  Returns single dataset
            % OUT = GET_DATASET(OBJ, 'id') returns a single dataset based on the
            % provided 'id'
            
            uri = sprintf('%s%s%s',obj.session.host,'datasets/',id);
            params = {'includeCollaborators' 'false' 'includeAncestors' 'false'...
                'session', obj.session.request.options.HeaderFields{2}};
            resp = obj.session.request.get(uri,params);
            out = BFBaseDataNode.createFromResponse(resp, obj.session);
        end
        
        function out = get_package(obj,id)
            % GET_PACKAGE  Returns single package
            % OUT = GET_PACKAGE(OBJ, 'id') returns a single package based on the
            % provided 'id'
            %
            uri = sprintf('%s%s%s',obj.session.host,'/packages/',id);
            params = {'includeAncestors' 'false' 'include' 'false'};
            resp = obj.session.request.get(uri,params);
            out = BFBaseDataNode.createFromResponse(resp, obj.session);
        end
        
        function out = get_collection(obj,id)
            % GET_PACKAGE  Returns collection
            % OUT = GET_PACKAGE(OBJ, 'id') returns a single package based on the
            % provided 'id'
            %
            uri = sprintf('%s%s%s',obj.session.host,'packages/',id);
            params = {'includeAncestors', 'false'};
            resp = obj.session.request.get(uri,params);
            out = BFBaseDataNode.createFromResponse(resp, obj.session);
        end
        
        function obj = handleGetDatasets(obj, resp)
            % DOCSTRING
            %
            obj.datasets = resp;
        end
        
        function delete_items(obj, thingIds)
            % DOCSTRING
            %
            uri = sprintf('%s%s',obj.session.host, 'data/delete');
            
            message = struct(...
                'things', []);
            
            message.things = thingIds;
            resp = obj.session.request.post(uri, message);
            
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
        
        function orgs = handleGetOrganizations(obj, resp)
            % HANDLEGETORGANIZATIONS handles the response from the 
            % organizations query.
            %
            len_org=length(resp.organizations);
            col_names = {'Name','Id'};
            orgs = cell2table(cell(len_org, length(col_names)));
            orgs.Properties.VariableNames=col_names;
            for i=1:len_org
                orgs(i, 1) = {resp.organizations(i).organization.name};
                orgs(i, 2) = {resp.organizations(i).organization.id};
            end
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
    end
    
end
