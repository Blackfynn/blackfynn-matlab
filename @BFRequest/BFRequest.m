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
      obj.options.Timeout = 60;
      try
        response = webwrite(uri, message, obj.options);
      catch ME              
        obj.handleError(ME);
      end
    end
    
    function response = put(obj, uri, message)
        try
            header(1) = matlab.net.http.field.GenericField('X-SESSION-ID',obj.options.HeaderFields{1,2});
            header(2) = matlab.net.http.field.GenericField('AUTHORIZATION',obj.options.HeaderFields{2,2});
            header(3) = matlab.net.http.field.ContentTypeField('application/json');
            params = matlab.net.http.MessageBody(message);
            
            if isa(message,'uint8')
                params.Payload = message;
            end
            request = matlab.net.http.RequestMessage('PUT', header, params);
            response = request.send( uri );
        catch ME
            obj.handleError(ME);
        end
    end
    
    function response = delete(obj, uri, message)
        % DELETE Makes DELETE HTTP request

        try
            header(1) = matlab.net.http.field.GenericField('X-SESSION-ID',obj.options.HeaderFields{1,2});
            header(2) = matlab.net.http.field.GenericField('AUTHORIZATION',obj.options.HeaderFields{2,2});
            header(3) = matlab.net.http.field.ContentTypeField('application/json');
            body = matlab.net.http.MessageBody(message); 
            
            request = matlab.net.http.RequestMessage('delete', header, body);
            requestOptions = matlab.net.http.HTTPOptions('ConvertResponse',false);
            response = request.send( uri, requestOptions );
        catch ME
            obj.handleError(ME);
        end
    end
    
    function success = setAPIKey(obj, key)
      headerFields = {'X-SESSION-ID' key ; 'AUTHORIZATION' ['BEARER ' key]};
      obj.options.HeaderFields = [headerFields ; obj.options.HeaderFields];
      success = true;
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
      elseif (strcmp(ME.identifier,'MATLAB:webservices:HTTP400StatusCodeError'))
        msg = [' Incorrectly formed web-request from client. Please report to the' ...
            ' Blackfynn team at support@blackfynn.com'];
        causeException = MException('MATLAB:Blackfynn:BadRequest',msg);
        ME = addCause(ME, causeException);
      elseif (strcmp(ME.identifier,'MATLAB:webservices:HTTP404StatusCodeError'))
        msg = [' Platform could not find one of the objects referred to in ' ...
            'the request.'];
        causeException = MException('MATLAB:Blackfynn:NotFound',msg);
        ME = addCause(ME, causeException);
      elseif (strcmp(ME.identifier, 'MATLAB:webservices:HTTP401StatusCodeError'))
        msg = [' The platform responded with a authorization error. '...
            'It is possible that you have been logged out'];
        causeException = MException('MATLAB:Blackfynn:BadRequest',msg);
        ME = addCause(ME, causeException);  
      elseif (strcmp(ME.identifier, 'MATLAB:webservices:CopyContentToDataStreamError'))
        msg = [' MATLAB could not send all the data in a single request.' ...
            'Try limiting the number of objects that you send per request'];
        causeException = MException('MATLAB:Blackfynn:webservices',msg);
        ME = addCause(ME, causeException);  
      end

      rethrow(ME);
    end
  end
  
end
