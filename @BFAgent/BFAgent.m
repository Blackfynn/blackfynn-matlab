classdef BFAgent
    %BFAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        location
    end
    
    methods
        function obj = BFAgent()
            %BFAGENT Construct an instance of this class
            %   Detailed explanation goes here
            
            % TODO: Make this work for windows/linus
            obj.location = '~/.blackfynn-agent/build/blackfynn-agent';
        end
        
        function status = login(obj, token, secret)
            %LOGIN Login of the agent
            
            % Login with agent if agent is installed
            status = 1;
            if exist('~/.blackfynn-agent/build/blackfynn-agent','file')
                [status, ~] = system(sprintf('%s login --key %s --secret %s', obj.location, token, secret));
                if status
                    warning('Blackfynn Agent could not be initialized; some functionality might not work');
                end
            else
                warning('Blackfynn Agent could not be initialized; some functionality might not work');
            end
            
        end
        
        function status = upload(obj, datasetId, path)
            
            % THIS IS VERY MUCH IN BETA -- Using the Agent to upload from
            % Matlab.
            cmd = sprintf('%s upload %s --dataset %s',obj.location, ...
                path, datasetId);
            [status, ~] = system(cmd);
            
        end
    end
end

