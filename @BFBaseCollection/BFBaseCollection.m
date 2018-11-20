classdef (Abstract) BFBaseCollection < BFBaseDataNode
    % BFBASECOLLECTION Abstract class which is extended by both
    % BFCOLLECTIONS and BFDATASETS.
    %
    % Objects of this class have a set of 'items' which can either be a
    % datapackage or a datacollection.
    %
    % See also:
    %   BFCollection, BFDataset
    
    
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
        function obj = BFBaseCollection(session, id, name, type)
            % BFBASECOLLECTION Constructor of the BFBASECOLLECTION class
            %   OBJ = BFBASECOLLECTION(SESSION, 'id','name','type') creates
            %   an instance of the BFBASECOLLECTION class.
            
            narginchk(4,4);
            obj = obj@BFBaseDataNode(session, id, name, type);
        end
        
        function out = listItems(obj)                           
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
                    out(i,1) = {item(i).id_};
                    out(i,2) = {item(i).name};
                end
            else
                len_items=length(item);
                for i=1:len_items
                    fprintf('ID: "%s", Name: "%s"\n',...
                        item(i).id_, item(i).name);
                end
            end

        end
                
        function folder = createFolder(obj, name)               
            % CREATEFOLDER creates a new folder within the object.
            %   FOLDER = CREATEFOLDER(OBJ, 'Name') creates a folder with the
            %   specified 'Name' and returns the newly created folder. If
            %   a foler with 'Name' already exists, no new folder is
            %   created.
            %   FOLDER = CREATEFOLDER(OBJ, 'Name', 'Description') creates a
            %   folder with the specified 'Name' and 'Description' and
            %   returns the newly created folder.
            %
            %   You can also provide a path for the 'Name'. This will
            %   result in the creation of multiple nested folders.
            % 
            %   Example:
            %
            %       folder = ds.CREATEFOLDER('New_folder')
            %       folder = ds.CREATEFOLDER('New_folder_2,'description')
            %
            %       folder = ds.CREATEFOLDERS('folder1/folder2/folder3')
            %
            %   See also:
            %       Blackfynn, BFDataset.listitems
            
            switch class(obj)
                case 'BFCollection'
                    datasetId = obj.datasetId;
                    parentId = obj.id_;
                case 'BFDataset'
                    datasetId = obj.id_;
                    parentId = '';
                otherwise
                    error('Object must be a dataset or a collection');
            end
            
            splitPath = split(name, '/');
            
            % Check if folder exists, if not --> create
            itemNames = {obj.items.name};
            itemMatchIdx = strcmp(splitPath{1},itemNames);
            if any(itemMatchIdx)
                folder = obj.items(itemMatchIdx);
            else
                resp = obj.session_.mainAPI.createFolder(datasetId, parentId, splitPath{1});
                obj.session_.updateCounter = obj.session_.updateCounter +1;
                folder = BFCollection.createFromResponse(resp, obj.session_);
            end

            % If path provided, create nested folders.
            if length(splitPath) > 1
                newPath = sprintf('%s/',splitPath{2:end});
                newPath = newPath(1:end-1);
                folder = folder.createFolder(newPath);
            else
                % Get folder (and make sure this is same handle stored in obj)
                itemNames = {obj.items.name};
                folder = obj.items(strcmp(splitPath{1},itemNames));
            end  
        end
                
        function value = get.items(obj)                         
            % Getter for items property 
            % Dynamically loads items during first access

            if obj.checked_items && (obj.updateCounter == obj.session_.updateCounter)
                value = obj.items_;
            else
                if isa(obj, 'BFDataset')
                    response = obj.session_.mainAPI.getDataset(obj.id_);          
                else
                    response = obj.session_.mainAPI.getPackage(obj.id_, ...
                        true, false);
                end
                
                % If object has children, create the children objects 
                if ~isempty(response.children)
                    children(length(response.children)) = ...
                        BFCollection('','','','');
                    for i=1:length(response.children)
                        children(i) = BFBaseDataNode.createFromResponse(...
                            response.children(i), obj.session_);
                    end
                else
                    children = BFBaseDataNode.empty();
                end
                obj.items_ = children;
                obj.checked_items = true;
                value = children;
                
                obj.updateCounter = obj.session_.updateCounter;
            end
        end
    end
    
    methods (Access = protected)                            
        function s = getFooter(obj)
            %GETFOOTER Returns footer for object display.
            if isscalar(obj)
                url = sprintf('%s/%s/datasets/%s/viewer/%s',obj.session_.web_host,obj.session_.org,obj.datasetId,obj.id_);
                s = sprintf(' <a href="matlab: Blackfynn.displayID(''%s'')">ID</a>, <a href="matlab: Blackfynn.gotoSite(''%s'')">View on Platform</a>, <a href="matlab: methods(%s.empty)">Methods</a>',obj.id_,url,class(obj));
            else
                s = '';
            end
        end
    end

end

