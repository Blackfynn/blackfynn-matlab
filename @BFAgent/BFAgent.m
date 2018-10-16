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
            
            % TODO: Make this work for windows/linus
            obj.location = '~/.blackfynn-agent/build/blackfynn-agent';
        end
    
        function status = login(obj, token, secret)
            %LOGIN Open a session using the Blackfynn Agent.
            %   STATUS = LOGIN(OBJ, 'token', 'secret') passes the API token
            %   and secret to the Blackfynn agent to open a session in the
            %   same environment as the Blackfynn Matlab client.
            
            % Login with agent if agent is installed
            status = 1;
            if exist(obj.location,'file')
                [status, ~] = system(sprintf('%s login --key %s --secret %s', obj.location, token, secret));
                if status
                    warning('Blackfynn Agent could not be initialized; some functionality might not work');
                end
            else
                warning('Blackfynn Agent could not be initialized; some functionality might not work');
            end
            
        end
        
        function status = upload(obj, datasetId, path)
            %UPLOAD Upload data from MATLAB using the Blackfynn Agent
            %   STATUS = UPLOAD(OBJ, 'datasetId', 'path') uploads all data
            %   in the folder specified in 'path'. 
            %            %
            %   This method is still very much in beta as visualization of
            %   status does not work well from within MATLAB. You can also
            %   use the agent directly from the command line for more
            %   comprehensive feedback.
                     
            cmd = sprintf('%s upload %s --dataset %s',obj.location, ...
                path, datasetId);
            [status, info] = system(cmd);
            
        end
    end
end

