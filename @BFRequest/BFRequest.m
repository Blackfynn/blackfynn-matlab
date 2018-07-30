classdef BFRequest < handle
  % BFREQUEST Class representing a web-request to Blackfynn.
  
  properties
    options
    getRequest
  end
  
  methods
    function obj = BFRequest()
      obj.options = weboptions();
      obj.options.CertificateFilename = '';
      obj.options.Timeout = 120;
    end
    
    function response = get(obj, uri, params)
     obj.options.MediaType = 'application/x-www-form-urlencoded';
     try
      response = webread(uri, params{:}, obj.options);
     catch ME
       obj.handleError(ME);
     end
    end
    
    function response = post(obj, uri, message)
      obj.options.MediaType = 'application/json';
      try
        response = webwrite(uri, message, obj.options);
      catch ME
        obj.handleError(ME);
      end
    end
    
    function response = put(obj, uri, message)
        obj.options.MediaType = 'application/json';
        obj.options.RequestMethod = 'put';
        try
            response = webwrite(uri, message, obj.options);
        catch ME
            obj.handleError(ME);
        end
    end
    
    function response = delete(obj, uri, message)
        % DELETE Makes DELETE HTTP request
        %
        obj.options.MediaType = 'application/json';
        obj.options.RequestMethod = 'delete';
            try
                response = webwrite(uri, message, obj.options);
            catch ME
                obj.handleError(ME);
            end
    end
    
    function obj = setAPIKey(obj, key)
      headerFields = {'X-SESSION-ID' key ; 'AUTHORIZATION' ['BEARER ' key]};
      obj.options.HeaderFields = [headerFields ; obj.options.HeaderFields];
    end
    
    function obj = setOrganization(obj, org)
      headerField = {'X-ORGANIZATION-ID' org};
      obj.options.HeaderFields = [headerField ; obj.options.HeaderFields];
    end
    
    function err = handleError(~, ME) %#ok<STOUT>
      
      if (strcmp(ME.identifier,'MATLAB:webservices:HTTP403StatusCodeError'))
        msg = [' Blackfyn user does not have the right permissions on the ' ...
          'Blackfynn platform to perform this action.'];
        causeException = MException('MATLAB:Blackfynn:unauthorized',msg);
        ME = addCause(ME, causeException);       
      end
      
      rethrow(ME);
    end
  end
  
end
