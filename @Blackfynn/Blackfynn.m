classdef (Sealed) Blackfynn < BFBaseNode
    
    properties(SetAccess = private)
        profile
        datasets
    end
    
    methods
        function obj = Blackfynn(varargin)
            % BLACKFYNN  Primary class for interacting with Blackfynn platform.
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
    % end of methods    
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
            uri = sprintf('%s%s%s',obj.session.host,'packages/',id);
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
        
    % end of hidden methods
    end
    
    methods(Static, Hidden)
        
        function home = getHome()
            % GETHOME gets home directory  and BF config
            % path for the OS in use.
            %
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
        
        function profiles()
            %PROFILES  show all the configuration profiles.
            %
            home = Blackfynn.getHome;
            bfdir = '.blackfynn';
            fname = 'config.ini';
            dirpath = fullfile(home, bfdir);
            fullpath = fullfile(dirpath, fname);
            
            % get home directory to set profile
            if exist(dirpath, 'dir')
                config = IniConfig();
                status = config.ReadFile(fullpath);
                
                sections = config.GetSections;
                for i=1: length(sections)
                    display(sections{i});
                end
                
            else
                fprintf('No profiles created, use SETUP to create profile');
            end
        end
        
        function setup()
            %SETUP  Setup a profile for the Blackfynn client
            %
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
        
    % end of Static methods
    end
    
end
