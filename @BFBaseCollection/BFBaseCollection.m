classdef BFBaseCollection < BFBaseDataNode
    % Base objetc used for Collections and Datasets. Both ``BFCollections`` and
    % ``BFDatasets`` extend this class.
    
    properties (Dependent)
        items
    end
    
    properties (Hidden)
        items_  =  BFBaseDataNode.empty();
        items__ =  BFBaseDataNode.empty();
        checked_items = false;
    end

    methods
        function obj = BFBaseCollection(varargin)
            %BFBASECOLLECTION Base class used for both ``Dataset`` and ``Collection``
            %
            %
            obj = obj@BFBaseDataNode(varargin{:});
        end
        
        function show_items(obj)
            % SHOW_ITEMS displays all of the items that reside within
            % a dataset, package or collection in the console. The output is
            % displayed in the format:
            %       ``Name: 'element_name', Id: 'package_id'``
            %
            %
            % Examples:
            %
            %           Get all the datasets under your current Organization::
            %
            %               >> bf.datasets.show_items
            %
            %           Get all the packages under a dataset::
            %
            %               >> ds = bf.get(dataset_id);
            %               >> ds.show_items
            %
            len_obj = length(obj);
            if len_obj == 1
                item = obj.items;
            else
                item = obj;
            end
            len_items=length(item);
            for i=1:len_items
                fprintf('ID: "%s", Name: "%s"\n',...
                    item(i).get_id, item(i).name);
            end
        end
        
        function out_table = items2table(obj)
            % ITEMS2TABLE stores all of the items that reside within
            % a dataset, package or collection in a MATLAB table. The output is
            % a table that looks as follows:
            %
            %               +---------------+-------------+
            %               | Name          | ID          |
            %               +===============+=============+
            %               | element_name  | element_id  |
            %               +---------------+-------------+
            %
            %
            % Examples:
            %
            %           Store all the dataset names and IDs under your current
            %           Organization in MATLAB table::
            %
            %               bf.datasets.items2table
            %
            %           Store all the package names and IDs under a dataset in a MATLAB
            %           table::
            %
            %               >> ds = bf.get(dataset_id);
            %               >> ds.items2table
            %
            len_obj = length(obj);
            if len_obj == 1
                item = obj.items;
            else
                item = obj;
            end
            len_items=length(item);
            col_names = {'Name', 'ID'};
            out_table = cell2table(cell(len_items, length(col_names)));
            out_table.Properties.VariableNames = col_names;
            for i=1:length(item)
                out_table(i,1) = {item(i).name};
                out_table(i,2) = {item(i).get_id};
            end
        end
        
        function out_collection = create_collection(obj, name, varargin)
            % CREATE_COLLECTION creates a new collection within the object.
            %
            % Args:
            %       name (str): name of the collection
            %       description (str, optional): description of the created collection
            %
            % Returns:
            %           ``BFCollection``: Created collection
            %
            % Examples:
            %
            %           Create a new collection in a dataset and then create another
            %           collection inside the created collection::
            %
            %               >> col_01 = ds.create_collection('new_collection',...
            %               'this collection contains the new samples');
            %               >> col_02 =...
            %               col_01.create_collection('other_collection',... 
            %               'this collection contains samples of type A');
            %
            %
            uri = sprintf('%s%s',obj.session.host,'packages/');
            description='';
            
            if nargin > 2
                description = varargin{1};
            end
            
            switch class(obj)
                case 'BFCollection'
                    message = struct('name', name,...
                        'parent', obj.get_id,...
                        'description', description,...
                        'packageType', 'Collection',...
                        'properties', [],...
                        'dataset', obj.datasetId);
                case 'BFDataset'
                    message = struct('name', name,...
                        'description', description,...
                        'packageType', 'Collection',...
                        'properties', [],...
                        'dataset', obj.id);                    
                otherwise
                    error('Object must be a dataset or a collection');
            end
            resp = obj.session.request.post(uri, message);
            out_collection = BFCollection.createFromResponse(resp, obj.session);
        end
        
        function upload(obj, varargin)
            % UPLOAD uploads files to the blackfynn platform.
            %            
            switch class(obj)
                case 'BFDataset'
                    dataset_id = obj.get_id;
                case 'BFCollection'
                    destination_id = obj.get_id;
                    dataset_id = obj.datasetId;
            end
         
            creds = obj.get_upload_credentials(dataset_id);
            %TODO: complete method to upload files to S3
                
        end
        
        function value = get.items(obj)
            % get the items that reside within a ``Collection``.
            %
            if obj.checked_items
                value = obj.items__;  % Return Matlab representation of objects.
            else
                % Check items
                uri = sprintf('%s%s%s',obj.session.host, '/datasets/', obj.id);
                params = {'api_key', obj.session.request.options.HeaderFields{2}};
                resp = obj.session.request.get(uri,params);
                
                % Create items
                if ~isempty(resp.children)
                    value(length(resp.children)) = BFCollection('','','','');
                    for i = 1:length(resp.children)
                        curItem = resp.children(i);
                        if isa(curItem, 'cell')
                            curItem = curItem{1,1};
                        end
                        value(i) = BFBaseDataNode.createFromResponse(curItem, obj.session);
                        obj.items__(i) = value(i);
                    end
                    obj.checked_items = true;
                else
                    value =  BFBaseDataNode.empty();
                end
            end
        end
    end
    
    methods (Access = protected)
        function s = getFooter(obj)
            if isscalar(obj)
                objId = obj.id;
                s = sprintf(['  <a href="matlab: display(''obj.id: %s'')"'...
                    '>ID</a>, <a href="matlab: Blackfynn.gotoSite">'...
                    'Webapp</a>, <a href="matlab: methods(%s)">Methods</a>']...
                    ,objId,class(obj));
            else
                s = '';
            end
        end
    end
    
    methods (Hidden, Access=private)
        
        function out = get_upload_credentials(obj, dataset_id, varargin)
            uri = sprintf('%s%s%s', obj.session.host, ...
                'security/user/credentials/upload/', dataset_id);
            params={};
            resp = obj.session.request.get(uri, params);
            out=resp;
        end
        
    end    
end

