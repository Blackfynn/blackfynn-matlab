classdef BFSession < handle
  %BFSESSION  Class representing a Blackfynn connection session
  
  properties
    request         % Request object
    host            % API host
    streaming_host  % Streaming Host
    api_key         % session key
  end

  properties (Access = private, Constant)
    streamingHost =  'https://streaming.blackfynn.io';
    serverUrl     =  'https://api.blackfynn.io/';
  end
  
  methods (Static)
    function hosts = getDefaultHosts()
      % GETDEFAULTHOSTS  Returns the default hosts for a Blackfynn session
      
      hosts = struct('host',BFSession.serverUrl, ...
        'streamingHost',BFSession.streamingHost);
    end
  end
  
  
end