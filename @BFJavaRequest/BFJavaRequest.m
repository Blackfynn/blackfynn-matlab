classdef BFJavaRequest
    %BFJAVAREQUEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        message
    end
    
    methods
        function obj = BFJavaRequest()
            %BFJAVAREQUEST Construct an instance of this class
            %   Detailed explanation goes here
            obj.message = 2;
        end
    end
    
    methods(Static, Sealed = true)
        function out = blackfynn_get(params_a, chans_a, ...
                streaming_host_a, endPoint_a)
            %BLACKGYNN_GET Summary of this method goes here
            %   Detailed explanation goes here
            br = blackfynn.Request('');
            response=br.RequestService(string(params_a),chans_a,...
                streaming_host_a, endPoint_a);
            out = BFJavaRequest.parse_response(response, chans_a);
        end        
    end
    
    methods (Static)
        function ts_struct = parse_response(response_array_a, chans_a)
            out = [];
            json_resp = jsondecode(char(response_array_a));
            [r,c,d] = size(json_resp);
            ts_struct = zeros(c,r+1);
            for i = 1 : length(chans_a)
                out=squeeze(json_resp(i,:,:));
                % set first column of matrix as time
                if i == 1
                    ts_struct(:,1) = out(:,1);
                end
                ts_struct(:,i+1) = out(:,2);
            end
        end
    end
end

