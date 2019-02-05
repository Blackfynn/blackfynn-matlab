classdef BFDataset < BFBaseCollection
    % BFDATASET  Representation of a Dataset object.
    %   A DATASET on the Blackfynn platform consists of a collection of
    %   files, a series of metadata objects and users. A dataset is the
    %   priciple container for data on the platform.
    
    properties
        description     % Description of the dataset
    end
    
    properties (SetAccess = private)
        status = "NO_STATUS" % Status of package
    end
    
    properties (Dependent)
        models          % Models that are defined within the dataset
    end
    
    properties (Access = private)
        models_
        modelsChecked = false
    end
    
    methods
        function value = get.models(obj)
            % GET_MODELS gets and caches the models for dataset.
            %
            if obj.modelsChecked
                value = obj.models_;
            else
                obj.models_ = obj.getModels_();
                value = obj.models_;
                obj.modelsChecked = true;
            end
        end
        
        function model = createModel(obj, name, description)
            %CREATEMODEL  Creates a model in the dataset
            %   MODEL = CREATEMODEL(OBJ, 'name', 'description) creates a
            %   model in the dataset with 'name' and a 'description'. The
            %   model name needs to be unique in the dataset. It returns
            %   the created model.
            %
            %   NOTE: the name of the model will be modified to contain no
            %   spaces or non-characters. However, the provided name will
            %   always be used for visualization in the web application,
            %
            %   For example:
            %       BF = Blackfynn()
            %       DS = BF.datasets(1)
            %       DS.createModel('Patient', 'This is a patient model')
            %
            %   See also: 
            %       BFDataset.createRecord, BFDataset.deleteModel
            
            if ~obj.modelsChecked
                obj.models_ = obj.getModels_();
                obj.modelsChecked = true;
            end
            
            response = obj.session_.conceptsAPI.createModel(obj.id_, name, description);
            model = BFModel.createFromResponse(response, obj.session_, obj);
            obj.models_ = [obj.models_ model];                
            
        end
        
        function out = listModels(obj)
            %LISTMOELS  Displays a list of models for the dataset
            %   OUT = LISTMDOELS(OBJ) returns a table of the model names
            %   other information in a Matlab table. This can be used to
            %   quickly visualize the available models in the current
            %   dataset.
            
            idx = 1:length(obj.models);
            idx = idx';
            name = {obj.models.name}';
            nrRecords = [obj.models.nrRecords]';
            
            out = table(idx,name,nrRecords);
            
        end
        
        function obj = upload(obj, path, varargin)
            %UPLOAD Upload data from MATLAB using the Blackfynn Agent
            %   OBJ = UPLOAD(OBJ, 'path') uploads all files from the folder
            %   specified in the 'path' to the platform.
            %
            %   OBJ = UPLOAD(..., 'folder', 'toPath') uploads the files to
            %   a specific path in the dataset. Folders will be created if
            %   the path does not exist yet. Separate folders using '/',
            %   for example: 'data/experiment1/trial1'.
            %
            %   OBJ = UPLOAD(..., 'recursive', 'true') recreates the folder
            %   structure relative to the specified folder on the platform
            %
            %   OBJ = UPLOAD(..., 'include', 'includeStr') will only upload
            %   the files that match the 'includeStr' expression. The
            %   include string should be formatted as a globbing pattern.
            %   For examples, look here:
            %   http://tldp.org/LDP/GNU-Linux-Tools-Summary/html/x11655.htm
            %
            %   OBJ = UPLOAD(..., 'exclude', 'excludeStr') will exclude
            %   files that match the 'excludeStr' expression. The exclusion
            %   string should be formatted in the same way as the inclusion
            %   string.
            %
            %   For example:
            %
            %       bf = Blackfynn();
            %       ds = bf.datasets(1);
            %       ds.upload('~/Desktop/myFolder');
            %
            %       ds.upload('~/Desktop/myFolder', 'folder', 'folder1/folder2');
            %
            %       ds.upload('~/Desktop/myFolder', 'inlcude', '*.dcm');
            %       ds.upload('~/Desktop/myFolder', 'inlcude', '{*.dcm,*.csv}')
            %       
            %       ds.upload('~/Desktop/myFolder', 'exclude', '*.DS_Store');
            %       

            if nargin > 2
                assert(mod(length(varargin),2) == 0,'Incorrect number of input arguments');
            end
            
            agent = obj.session_.agent;
            agent.upload(obj, path, varargin{:});
            
            % Invalidate items in memory for dataset object
            obj.checked_items = false;
        end

    end
    
    methods (Sealed = true)
        
        function obj = BFDataset(session, id, name)
            % BFDATASET Constructor of the BFDATASET Class
            %   OBJ = BFDATASET(SESSION, 'id', 'name') creates a
            %   BFDATASET instance where SESSION is the BFSESSION object,
            %   'id' is the id of the dataset and 'name' is the name of the
            %   dataset.            
            
            narginchk(3,3);
            obj = obj@BFBaseCollection(session, id, name, 'DataSet');
        end
        
        function obj = update(obj)
            % UPDATE updates dataset on the platform.
            %   OBJ = UPDATE(OBJ) pushes changes to the object that were
            %   created locally and updates the objects on the platform.
            %
            %   Changes to objects such as the name and the description are
            %   not automatically pushed to the Blackfynn servers. Users
            %   will have to call the update function manually to push
            %   these changes.
            %
            %   For example:
            %       DS = BF.datasets(1);
            %       DS.name = 'Updated name';
            %       DS.update();
            %
            %   See also:
            %       Blackfynn

            obj.session_.mainAPI.updateDataset(obj.id_, obj.name, obj.description);
             
        end
        
    end
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s',obj.session_.web_host,obj.session_.org,obj.id_);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s.empty)">Methods</a>',obj.id_,url,class(obj));
            else
                s = '';
            end
        end
        
    end
    methods (Access = private)
        function m = getModels_(obj)
            response = obj.session_.conceptsAPI.getModels(obj.id_);
            m = BFModel.empty(length(response),0);
            for i=1: length(response)
                m(i) = BFModel.createFromResponse(response(i), obj.session_, obj);
            end
        end
    end
    methods (Static, Hidden)
        function out = createFromResponse(resp, session)
            % CREATEFROMRESPONSE creates a BF dataset object from a
            % response.
            %
            content = resp.content;
            out = BFDataset(session, content.id, content.name);
            out.setDates(content.createdAt, content.updatedAt);
            
            if isfield(content, 'description')
                out.description = content.description;
            end
            if isfield(content, 'status')
                out.status = content.status;
            end
        end
    end
    
end