classdef (Abstract) BFBaseNode < handle
    % Base class to serve all Blackfynn objects.
    
    properties(Access = public)
        id
        session
    end
    
    methods
        
        function obj = BFBaseNode(varargin)
            % BFBASENODE Is a method to serve all objects.
            
            if (nargin > 0)
                obj.id = varargin{2};
                obj.session = varargin{1};
            end
        end
        
        function move(obj, dest, varargin)
            %MOVE  Moves objects to a destination collection
            %
            % Args:
            %       destination (str or object): Destination collection object or ID.
            %       things (list of objects): Package objects to move.
            % 
            % Examples:
            %
            %           Move two packages to a collection using the collection's
            %           object::
            %
            %               bf.move(my_collection, pkg1, pkg2)
            %
            %           Move `collection1` into another collection using the
            %           destination ID and the object of ``collection1``::
            %           
            %               bf.move('N:collection:ae8d7f6f-f35a-4029-b78e-5bd1525ade2d', col1)
            %
            % Note:
            %
            %       Data Packages cannot be moved across datasets.
            %
            uri = sprintf('%s%s',obj.session.host,'data/move');
            
            destid = dest;
            if isa(dest,'BFBaseCollection')
                destid = dest.get_id;
            end
            
            thingIds{length(varargin)} = '';
            for i = 1 : length(varargin)
                thingIds{i} = varargin{i}.get_id;
            end
            
            if length(varargin) == 1
                thingIds{2} = '';
            end
            
            message = struct(...
                'things', [],...
                'destination', destid);
            
            message.things = thingIds;
            obj.session.request.post(uri, message);
        end
        
        function delete(obj, varargin)
            %DELETE Deletes an object from the platform.
            %
            % Args:
            %    things (list): ID or object of items to delete.
            %
            % Examples:
            %
            %           In this example ``col`` and ``pkg`` are Collection  and
            %           DataPackage objects respectively.
            %
            %           Remove multiple items through their objects or
            %           IDs::
            %
            %               bf.delete('N:collection:117775eb-2222-47fc-aa8f-7a69ad7a04b2', col, pkg)
            %
            %
            % Note:
            %       For safety, datasets cannot be deleted from the client.
            %
            % Note:
            %       When deleting a ``Collection`` all child items will also
            %       be deleted.
            %
            things{length(varargin)} = '';
            
            for i = 1 : length(varargin)
                switch class(varargin{i})
                    case {'string', 'char'}
                        things{i} = char(varargin{i});
                    case {'BFTimeseries','BFCollection',...
                            'BFDataPackage', 'BFTabular'}
                        things{i} = varargin{i}.get_id;
                    case 'BFDataset'
                        msg=['Datasets cannot be deleted from the client.'...
                            '\n [%s] will not be deleted'];
                        warning(msg, varargin{i}.name)
                end
            end
            things=things(~cellfun('isempty',things));
            obj.delete_items(things)
        end
        
        function out = get(obj, thing)
            %GET  Returns any object based on the Blackfynn ID.
            %
            % Args:
            %       ID (str): ID of the package that is being retrieved.
            %
            % Returns:
            %          Object: object for the package that is
            %          being retrieved
            %
            % Example:
            %
            %           Get a package from the platform and save the object in `pkg`::
            %
            %               pkg =
            %               bf.get('N:package:113335eb-2222-47fc-aa8f-7a90a46a0455');
            %
            types = split(thing,':');
            assert(length(types) == 3, 'Incorrect object ID');
            type = types{2};
            
            switch (type)
                case 'dataset'
                    out = obj.get_dataset(thing);
                case 'package'
                    out = obj.get_package(thing);
                case 'collection'
                    out = obj.get_collection(thing);
                    
                otherwise
                    fprintf(2, 'Incorrect object ID');
            end
        end
        
        function out = create_dataset(obj, name, varargin)
            % CREATE_DATASET creates a new dataset under
            % the current organization with the provided ``name``. The newly
            % created dataset is returned from the method.
            %
            % Args:
            %       name (str): name of the new dataset
            %       description (str, optional): description of the dataset
            %
            % Returns:
            %           ``BFDataset``: created dataset.
            %
            % Examples:
            %
            %           Create a new dataset called ``new dataset`` with a
            %           description::
            %
            %               bf = Blackfynn # create client instance
            %               bf.create_dataset('new dataset', 'this is a test dataset')
            %
            %
            uri = sprintf('%s%s',obj.session.host,'datasets/');
            description='';
            
            if nargin > 2
                description = varargin{1};
            end
            
            message = struct(...
                'name', name,...
                'description', description,...
                'properties', []);
            
            resp = obj.session.request.post(uri, message);
            obj.get_datasets();
            out = obj.get(resp.content.id);
            
        end
        
        function out = get_organizations(obj)
            % GET_ORGANIZATIONS  Returns a table of organizations that the user
            % belongs to.
            %
            % Note:
            %     The user will need to create a separate API token for each
            %     organization in order to access the data through the API. A session
            %     can only interact with data from a single organization.
            %
            % Examples:
            %
            %         Get all the organizations for a user profile::
            %
            %             bf=Blackfynn('profile_name')
            %             bf.get_organizations
            %
            %             ans = 
            %
            %                Name                                 Id                          
            %             ___________    _____________________________________________________
            %             'Blackfynn'    'N:organization:c9055555-3333-4444-9c2a-8d23542c4581'
            %
            uri = 'organizations/';
            params = {'includeAdmins' 'false'};
            endPoint = sprintf('%s%s%s',obj.session.host, uri);
            
            request = obj.session.request;
            resp = request.get(endPoint, params);
            out = obj.handleGetOrganizations(resp);
        end
    end
    
    methods (Access = protected)
        function info = specialPropsInfo(obj)
            % DOCSTRING
            %
            info = struct('name',{},'size',[0 0], 'format','');
        end
    end
    
    methods (Sealed = true)
        
        function m = methods(obj)
            %METHODS  Shows all methods associated with the object.
            %   METHODS(OBJ) displays all methods of the object ``OBJ`` that
            %   are defined for the subclass ``OBJ``.
            %
            blockmethods = {'addlistener' 'delete' 'disp' 'eq' 'ge' 'ne' 'gt'  ...
                'le' 'lt' 'notify' 'isvalid' 'findobj' 'findprop' 'copy' ...
                'addprop' 'subsref' 'setsync' 'getTSIprop' 'populateAnnLayer'...
                };
            
            if nargout
                fncs = builtin('methods', obj);
                blockIdx = cellfun(@(x) any(strcmp(x, blockmethods)), fncs);
                fncs(blockIdx) = [];
                m = fncs;
                return;
            end
            
            %Display methods sorted by the length of the method name and
            %then alphabetically.
            
            fprintf('\n%s Methods:\n',class(obj));
            
            %Define indenting steps for unusual long method names.
            STEP_SIZES = [20 23 26 29 32 35 38 41 44 47 50];
            SAMPLES_TOO_CLOSE = 2;
            
            fncs = builtin('methods', obj);
            blockIdx = cellfun(@(x) any(strcmp(x, [blockmethods])), fncs);
            fncs(blockIdx) = [];
            
            % -- Get H1 lines
            txts{1,length(fncs)} = [];
            for i=1:length(fncs)
                aux = help(sprintf('%s.%s',class(obj), fncs{i}));
                tmp = regexp(aux,'\n','split');
                tmp = regexp(tmp{1},'\s*[\w\d()\[\]\.]+\s+(.+)','tokens','once');
                if ~isempty(tmp)
                    txts(i) = tmp;
                end
            end
            
            %The class specific methods
            [~,I] = sort(lower(fncs));
            fncs = fncs(I);
            txts = txts(I);
            
            L = cellfun('length', fncs);
            for iSize = 1:length(STEP_SIZES)
                if iSize == length(STEP_SIZES)
                    iUse = 1:length(txts);
                else
                    iUse = find(L <= STEP_SIZES(iSize) - SAMPLES_TOO_CLOSE);
                end
                txtsUse = txts(iUse);
                fncsUse = fncs(iUse);
                LUse    = L(iUse);
                txts(iUse) = [];
                fncs(iUse) = [];
                L(iUse)    = [];
                for i=1:length(txtsUse)
                    link = sprintf('<a href="matlab:help(''%s>%s'')">%s</a>',...
                        class(obj),fncsUse{i},fncsUse{i});
                    pad = char(32*ones(1,(STEP_SIZES(iSize)-LUse(i))));
                    disp([ ' ' link pad txtsUse{i}]);
                end
                
            end
            fprintf('\n\n');  
        end
    
    % end of sealed methods
    end
    
    methods (Static, Sealed = true)
        function gotoSite()
            %GOTOSITE  Opens the Blackfynn platform in an external browser.
            %
            web('app.blackfynn.io','-browser');
        end
        
    % end of static methods
    end
    
end