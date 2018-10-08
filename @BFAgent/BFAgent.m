classdef BFAgent
    %BFAGENT Representation of the Blackfynn Agent in Matlab
    %   The Blackfynn Agent is an application that provides a high
    %   performant CLI from the command line, and a deamon that runs in the
    %   background to facilitate high bamdwidth communication with the
    %   platform. 
    
    properties
        location    % Path of the blackfynn agent
    end
    
    methods
        function obj = BFAgent()
            %BFAGENT Construct an instance of the BFAgent
            
            % TODO: Make this work for windows/linus
            obj.location = '~/.blackfynn-agent/build/blackfynn-agent';
        end
        
        function status = login(obj, token, secret)
            %LOGIN Login of the agent
            %   This method sets the API key and secret for the Agent.
            
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
            
            % THIS IS VERY MUCH IN BETA -- Using the Agent to upload from
            % Matlab.
            cmd = sprintf('%s upload %s --dataset %s',obj.location, ...
                path, datasetId);
            [status, info] = system(cmd);
            
        end
    end
end

