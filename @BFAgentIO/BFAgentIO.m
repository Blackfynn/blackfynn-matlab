classdef (Sealed) BFAgentIO < WebSocketClient
    % BFAGENTIO Class handling communication with the Blackfynn Agent
    
    properties
        session_
        package
        received_data
        data
        ichunk = 0
    end
    
    properties(Constant)
        uri = 'localhost:9090'
    end
    
    methods
        function obj = BFAgentIO(session, package)
            % BFAGENTIO Constructor for objects of the BFAGENTIO class
            
            URI = sprintf('ws://%s/ts/query?package=%s&session=%s', ...
                BFAgentIO.uri, package, session.api_key);

            obj@WebSocketClient(URI);
            obj.session_ = session;
            obj.package = package;
            obj.received_data = java.util.HashMap;
            obj.data = java.util.HashMap;
        end
    end
    
    methods (Access = protected)
        function onOpen(~,message)
            % This function simply displays the message received
            fprintf('%s\n',message);
        end
        
        function onTextMessage(~,message)
            % This function simply displays the message received
            fprintf('Message received:\n%s\n',message);
        end
        
        function onBinaryMessage(obj, bytearray)
            status = "READY";
            response =  javaMethod('parseFrom','blackfynn.TsProto$AgentTimeSeriesResponse', bytearray);
            if response.hasChunk()
                fprintf('.')
                chunk = response.getChunk();                
                for ichan = 0: (chunk.getChannelsCount-1)
                    ch = chunk.getChannels(ichan);
                    chId = ch.get('id');
                    if ~obj.data.containsKey(chId)
                        map = java.util.ArrayList;
                        obj.data.put(chId, map);
                    else
                        map = obj.data.get(chId);
                    end
                    
                    dl = ch.getDataList;
                    map.addAll(dl);
                    
                end                
            elseif response.hasState()
                state = response.getState();
                status = string(state.getStatus);
            end
            if status == "READY"
                obj.ichunk = obj.ichunk + 1;
                obj.send('{"command": "next"}');
            elseif status == "DONE"
                obj.received_data.put('data', obj.data);
                if obj.Status
                    obj.send('{"command": "close"}');
                end
            else
                fprintf(2,'something is odd');
            end
        end  
        
        function onError(~,message)
            % This function simply displays the message received
            fprintf('Error: %s\n',message);
        end
        
        function onClose(~,message)
            % This function simply displays the message received
            fprintf('%s\n',message);
        end
    end
end

