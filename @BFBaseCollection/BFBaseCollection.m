classdef (Abstract) BFBaseCollection < BFBaseDataNode
    % BFBASECOLLECTION Abstract class with is extended by both
    % BFCOLLECTIONS and BFDATASETS.
    
    properties (Dependent)
        items   % The contents of a folder or a dataset.
    end
    
    properties (Hidden, Access = private)
        items__ =  BFBaseDataNode.empty();
        checked_items = false;
    end

    methods
        function obj = BFBaseCollection(varargin)       
            % Args: Empty, or [session, id, name, type]
            obj = obj@BFBaseDataNode(varargin{:});
        end
        
        function out = listitems(obj)                   
            % LISTITEMS Returns list of items in the dataset or collection. 
            %   LISTITEMS(OBJ) displays all of the items that reside within
            %   a dataset, package or collection in the console. 
            %
            %   OUT = LISTITEMS(OBJ) returns the items in the object as a
            %   table with the NAME and ID as column headers.
            %
            %   Example:
            %       BF = Blackfynn()
            %       DS = BF.get('dataset_id')
            %       DS.LISTITEMS()
            %
            %       ITEMS = DS.LISTITEMS()
            %
            %   See also:
            %       Blackfynn.get
       
            len_obj = length(obj);
            if len_obj == 1
                item = obj.items;
            else
                item = obj;
            end
            
            if nargout
                len_items=length(item);
                col_names = {'Name', 'ID'};
                out = cell2table(cell(len_items, length(col_names)));
                out.Properties.VariableNames = col_names;
                for i=1:length(item)
                    out(i,1) = {item(i).id};
                    out(i,2) = {item(i).name};
                end
            else
                len_items=length(item);
                for i=1:len_items
                    fprintf('ID: "%s", Name: "%s"\n',...
                        item(i).id, item(i).name);
                end
            end

        end
                
        function out = createfolder(obj, name, varargin)
            % CREATEFOLDER creates a new folder within the object.
            %   OUT = CREATEFOLDER(OBJ, 'Name') creates a folder with the
            %   specified 'Name' and returns the newly created folder.
            %   OUT = CREATEFOLDER(OBJ, 'Name', 'Description') creates a
            %   folder with the specified 'Name' and 'Description' and
            %   returns the newly created folder.
            % 
            %   Example:
            %
            %       F1 = DS.CREATEFOLDER('New_folder')
            %       F2 = DS.CREATEFOLDER('New_folder_2,'description')
            %
            %   See also:
            %       Blackfynn, BFDataset.listitems
            
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
            out = BFCollection.createFromResponse(resp, obj.session);
        end
        
        function value = get.items(obj)                 
            % Getter for items property 
            % Dynamically loads items during first access

            if obj.checked_items
                value = obj.items__;
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
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/viewer/%s',obj.session.web_host,obj.session.org,obj.datasetId,obj.id);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s)">Methods</a>',obj.id,url,class(obj));
            else
                s = '';
            end
        end
    end

       
end

