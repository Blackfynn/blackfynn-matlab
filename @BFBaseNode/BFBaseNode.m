classdef (Abstract) BFBaseNode < handle & matlab.mixin.CustomDisplay
    % Base class to serve all Blackfynn objects.
    
    properties(Access = protected)
        session     % Session ID
    end
    
    methods
        function obj = BFBaseNode(varargin)            
            if (nargin > 0)
                obj.session = varargin{1};
            end
        end
    end
    
    methods (Sealed = true)    
        function m = methods(obj)
            %METHODS  Shows all methods associated with the object.
            %   METHODS(OBJ) displays all methods of OBJ.
            %
            %   M = METHODS(OBJ) returns all methods of OBJ as a cell
            %   array
            
            blockmethods = {'addlistener' 'delete' 'disp' 'eq' 'ge' 'ne' 'gt'  ...
                'le' 'lt' 'notify' 'isvalid' 'findobj' 'findprop' 'copy' ...
                'addprop' 'subsref' 'setsync' 'getTSIprop' 'populateAnnLayer'...
                'listener'};
            
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
        
    end
    
    methods (Static, Sealed = true)
        function gotoSite()
            %GOTOSITE  Opens the Blackfynn platform in an external browser.
            
            web('app.blackfynn.io','-browser');
        end
    end
    
end