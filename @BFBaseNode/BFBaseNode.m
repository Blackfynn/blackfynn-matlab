classdef (Abstract) BFBaseNode < handle & matlab.mixin.CustomDisplay
    % BFBASENODE Abstract base-class for all Blackfynn objects.
    %   All objects stored on the blackfynn platform (including meta-data
    %   and files) are derived from the abstract BFBASENODE class. Each
    %   object will have an ID and an associated Blackfynn Session.
    %
    
    properties (Hidden)
        id_           % ID on Blackfynn platform
        createdAt_    % Timestamp when object was created
        updatedAt_    % Timestamp when object was updated
    end
    properties(Access = protected)
        session_     % Session ID
    end
    
    methods
        function obj = BFBaseNode(session, id)
            % BFBASENODE Constructor for the BFBASNODE CLASS
            %   OBJ = BFBASENODE(SESSION, 'id') creates an object of class
            %   BFBASENODE where SESSION is an object of class BFSESSION,
            %   and 'id' is the Blackfynn ID of the object.
            
            narginchk(2,2)
            if nargin
                obj.session_ = session;
                obj.id_ = id;
            end
        end
        

    end
    
    methods(Access = protected)
        function obj = setDates(obj, createdAt, updatedAt)
            % SETDATES Updates the create and update values of object
            %   OBJ = SETDATES('createDate', 'updateDate') sets the
            %   createdAt and updatedAt properties of the object. The input
            %   strings should follow the following expression:
            %   'yyyy-mm-ddTHH:MM:SS.FFF'. 
            
            obj.createdAt_ = datenum(createdAt, 'yyyy-mm-ddTHH:MM:SS');
            obj.updatedAt_ = datenum(updatedAt, 'yyyy-mm-ddTHH:MM:SS');
        end
    end
    
    methods (Sealed = true)    
        function varargout = methods(obj)
            %METHODS  Shows all methods associated with the object.
            %   METHODS(OBJ) displays all methods of OBJ.
            %
            %   M = METHODS(OBJ) returns all methods of OBJ as a cell
            %   array
            
            blockmethods = {'addlistener' 'delete' 'disp' 'eq' 'ge' 'ne' 'gt'  ...
                'le' 'lt' 'notify' 'isvalid' 'findobj' 'findprop' 'copy' ...
                'addprop' 'subsref' 'setsync' 'getTSIprop' 'populateAnnLayer'...
                'listener' 'cat' 'horzcat' 'vertcat'};
            
            if nargout
                [fncs, full_fncs] = builtin('methods', obj);
                blockIdx = cellfun(@(x) any(strcmp(x, blockmethods)), fncs);
                fncs(blockIdx) = [];
                varargout{1} = fncs;
                if nargout > 1
                    varargout{2} = full_fncs;
                end
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
    end
    
    methods (Static)
        function gotoSite()
            % GOTOSITE  Opens the Blackfynn platform in an external browser.
            %   GOTOSITE() opens a web browser and opens the platform
            %   application in the browser.
            
            web('app.blackfynn.io', '-browser');
        end
    end
    
end