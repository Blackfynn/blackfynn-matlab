classdef BFDataset < BFBaseCollection
    %BFDATASET  Representation of a Dataset objet on the Blackfynn platform
    
    properties
        description
    end
    
    properties (Dependent)
        models
    end
    
    properties (Access = private)
        models_
    end
    
    methods
        function value = get.models(obj)
            % GET_MODELS gets and caches the models for dataset.
            %
            if ~isempty(obj.models_)
                value = obj.models_;
            else
                obj.models_ = obj.session.conceptsAPI.getModels(obj.id);
                value = obj.models_;
            end
        end
        
        function obj = createModel(obj, name, description)
            %CREATEMODEL  Creates a model in the dataset
            %   OBJ = CREATEMODEL(OBJ, 'name', 'description) creates a
            %   model in the dataset with 'name' and a 'description'. The
            %   model name needs to be unique in the dataset.
            %
            %   NOTE: the name of the model will be modified to contain no
            %   spaces or non-characters. However, the provided name will
            %   always be used for visualization in the web application,
            %
            %   For example:
            %       BF = Blackfynn()
            %       DS = BF.datasets(1)
            %       DS.createModel('Patient','This is a patient model')
            %
            %   See also: 
            %       BFDataset.createRecord, BFDataset.deleteModel
            
            
            response = obj.session.conceptsAPI.createModel(obj.id, name, description);
            if isa(response,'struct')
                obj.models_ = [];
            else
                error('Unable to create model');
            end
        end
    end
    
    methods (Sealed = true)
        
        function obj = BFDataset(varargin)
            % Args: Empty, or [session, id, name, type]
            
            obj = obj@BFBaseCollection(varargin{:} );
        end
        
        function obj = update(obj)
            %UPDATE updates dataset on the platform.

            obj.session.mainAPI.updateDataset(obj.id, obj.name, obj.description);
             
        end
        
    end
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s',obj.session.web_host,obj.session.org,obj.id);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,url,class(obj));
            else
                s = '';
            end
        end
        
    end
    methods (Static, Hidden)
        function out = createFromResponse(resp, session)
            % CREATEFROMRESPONSE creates a BF dataset object from a
            % response.
            %
            content = resp.content;
            out = BFDataset(session, content.id, content.name, content.packageType);
            
            if isfield(content, 'description')
                out.description = content.description;
            end
        end
    end
    
end