classdef BFAgent
    %BFAGENT Representation of the Blackfynn Agent in Matlab
    %   The Blackfynn Agent is an application that provides a high
    %   performant CLI from the command line, and a deamon that runs in the
    %   background to facilitate high bamdwidth communication with the
    %   platform. 
    %
    %   Typically, users do not directly interact with BFAGENT objects and
    %   instead access its methods through the BLACKFYNN class. 
    %
    %   See also:
    %       Blackfynn
    
    properties
        location    % Path of the blackfynn agent
    end
    
    methods
        function obj = BFAgent()
            %BFAGENT Construct an instance of the BFAgent
            %   OBJ = BFAGENT() creates an instance representing the
            %   Blackfynn agent. The Blackfynn Agent is an application that
            %   provides a high performant CLI from the command line, and a
            %   deamon that runs in the background to facilitate high
            %   bamdwidth communication with the platform.
            %
            %   The Blackfynn agent needs to be installed separately
            %   following the instructions from
            %   https://developer.blackfynn.com/agent            
            
            if ismac
                obj.location = '/usr/local/opt/blackfynn/bin/blackfynn_agent';
            elseif isunix
                obj.location = '/opt/blackfynn/bin/blackfynn_agent';
            elseif ispc
                obj.location = 'C:\Program Files\Blackfynn\BFAgent.exe';
            else
                disp('Platform not supported')
            end
            
        end
    
        function status = login(obj, profileName)
            %LOGIN Open a session using the Blackfynn Agent.
            %   STATUS = LOGIN(OBJ, 'token', 'secret') passes the API token
            %   and secret to the Blackfynn agent to open a session in the
            %   same environment as the Blackfynn Matlab client.
            
            % Login with agent if agent is installed
            status = 1;
            if exist(obj.location,'file')
                [status, ~] = system(sprintf('"%s" profile switch %s', obj.location,profileName));
                if status
                    warning('Blackfynn Agent could not be initialized; some functionality might not work');
                end
            else
                warning('Blackfynn Agent could not be initialized; some functionality might not work');
            end
            
        end
        
        function upload(obj, dataset, path, varargin)
            %UPLOAD Upload data from MATLAB using the Blackfynn Agent
            %   UPLOAD(OBJ, DATASET, 'path') uploads all files from the
            %   folder specified in the 'path' to the platform. 
            %
            %   UPLOAD(..., 'folder', TOFOLDER) uploads the files to the
            %   folder TOFOLDER on the Blackfynn platform. TOFOLDER should
            %   be an object of class BFCOLLECTION in the specified
            %   DATASET.
            %
            %   UPLOAD(..., 'include', 'includeStr') will only upload the
            %   files that match the 'includeStr' expression.
            %
            %   UPLOAD(..., 'exclude', 'excludeStr') will exclude files
            %   that match the 'excludeStr' expression.
            %
            %   NOTE: When using MATLAB to upload files to the platform,
            %   each time the UPLOAD command is used, the exisiting queue
            %   is flushed. Therefore, you should never run multiple
            %   concurent upload sessions using MATLAB.
 
            assert(isa(dataset,'BFDataset'), 'DATASET needs to be of type BFDataset');
            assert(~mod(length(varargin),2),'Incorrect number of input arguments');
            
            folder = '';
            include = '';
            exclude = '';
            
            for i=1: 2: length(varargin)
                switch varargin{i}
                    case 'folder'
                        toPath = varargin{i+1};
                        assert(isa(toPath,'char'), 'FOLDER needs to be of type ''char''');
                        folder = dataset.createFolder(toPath);
                    case 'include'
                        include = varargin{i+1};
                        assert(isa(include,'char'), '''include'' needs to be of type ''char''');
                    case 'exclude'
                        exclude = varargin{i+1};
                        assert(isa(exclude,'char'), '''exclude'' needs to be of type ''char''');
                end
            end
            
                   
            cmd = sprintf('"%s" upload -f -O simple ',obj.location);
            
            if ~isempty(folder)
                cmd = [cmd sprintf('--folder=%s ',folder.id_)];
            else
                cmd = [cmd sprintf('--dataset=%s ',dataset.id_)];
            end
            if ~isempty(include)
                cmd = [cmd sprintf('--include=%s ',include)];
            end
            if ~isempty(exclude)
                cmd = [cmd sprintf('--exclude=%s ',exclude)];
            end
            
            cmd = [cmd sprintf('%s', path)];
            
            % Cancel existing queue
            system(sprintf('"%s" upload-status --cancel-all', obj.location));
            
            % Run uploader
            system(cmd);
                       
        end
    end
    
end

