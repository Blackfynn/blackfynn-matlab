classdef BFSession < handle
  %BFSESSION  Class representing a Blackfynn connection session
  
  properties
    request         % Request object
    host            % API host
    concepts_host   % Concepts API location
    streaming_host  % Streaming Host
    api_key         % session key
    web_host        % url to Blackfynn web app
    org             % Organization ID
    conceptsAPI     % ConceptsAPI instance
    mainAPI         % MainAPI instance
    agent           % Agent instance
  end

  properties (Access = private, Constant)
    streamingHost =  'https://streaming.blackfynn.io';
    conceptsHost  =  'https://concepts.blackfynn.io';
    serverUrl     =  'https://api.blackfynn.io';
    webHost       =  'https://app.blackfynn.io';
  end
  
  properties (Hidden, Access = {?BFBaseNode})
      updateCounter = 0  % Used to invalidate children after updates to organization of files.
  end
  
  methods
      function success = setAPIKey(obj, key)
        if isa(obj.request, 'BFRequest')
            success = obj.request.setAPIKey(key);
        else
            error('No request object provided, contact support@blackfynn.com');
        end
      end
  end
  
  methods (Static)
    function hosts = getDefaultHosts()
      % GETDEFAULTHOSTS  Returns the default hosts for a Blackfynn session
      
      hosts = struct('host',BFSession.serverUrl, ...
        'streamingHost',BFSession.streamingHost, ...
        'webHost', BFSession.webHost,...
        'conceptsHost', BFSession.conceptsHost);
    end
    
    
  end
  
  
end