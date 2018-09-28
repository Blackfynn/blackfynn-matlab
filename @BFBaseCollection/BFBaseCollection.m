classdef (Abstract) BFBaseCollection < BFBaseDataNode
    % BFBASECOLLECTION Abstract class with is extended by both
    % BFCOLLECTIONS and BFDATASETS.
    
    properties (Dependent)
        items   % The contents of a folder or a dataset.
    end
    
    properties (Hidden, Access = protected)
        items_ =  BFBaseDataNode.empty();
        checked_items = false;
        items_resp
        updateCounter = 0;
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
                
        function obj = createfolder(obj, name)
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
            
            switch class(obj)
                case 'BFCollection'
                    datasetId = obj.datasetId;
                    parentId = obj.id;
                case 'BFDataset'
                    datasetId = obj.id;
                    parentId = '';
                otherwise
                    error('Object must be a dataset or a collection');
            end
            
            obj.session.mainAPI.createFolder(datasetId, parentId, name);
            obj.session.updateCounter = obj.session.updateCounter +1;
        end
        
        function value = get.items(obj)                 
            % Getter for items property 
            % Dynamically loads items during first access

            if obj.checked_items && (obj.updateCounter == obj.session.updateCounter)
                value = obj.items_;
            else
                if isa(obj, 'BFDataset')
                    response = obj.session.mainAPI.getDataset(obj.id);          
                else
                    response = obj.session.mainAPI.getPackage(obj.id, ...
                        true, false);
                end
                
                % If object has children, create the children objects 
                if ~isempty(response.children)
                    children(length(response.children)) = ...
                        BFCollection('','','','');
                    for i=1:length(response.children)
                        children(i) = BFBaseDataNode.createFromResponse(...
                            response.children(i), obj.session);
                    end
                else
                    children = BFBaseDataNode.empty();
                end
                obj.items_ = children;
                obj.checked_items = true;
                value = children;
                
                obj.updateCounter = obj.session.updateCounter;
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

