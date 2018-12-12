classdef (Sealed) BFTabular < BFDataPackage
    %BFTABULAR  Object that represents a tabular package
    
    methods
        function obj = BFTabular(varargin)
            % BFTABULAR Base class used for ``BFTabular`` objects
            %
            % Args:
            %       ID (str): tabular package's ID
            %       name (str): name of the tabiular package
            %
            % Returns:
            %           ``BFTabular``: Tabular object
            %
            obj = obj@BFDataPackage(varargin{:});
        end
        
        function data = getData(obj, varargin)
            % GETDATA  get data from tabular package.
            %
            % Args:
            %       limit (int, optional): Max number of rows to return (1000 default)
            %       offset (int, optional): row offset
            %       orderBy (str, optional): column to order data
            %       orderDirection (str, optional): Ascending 'ASC' or descending 'DESC'
            %
            % Returns:
            %
            %       table: Tabular data
            %
            % Example:
            %
            %          Get 4 rows of data starting from the 3rd row of
            %          ``tab``, a ``BFTabular`` object::
            %           
            %               >> tab.getData('offset', 3, 'limit', 4)
            %
            %               ans =
            %             
            %               4×4 table
            %             
            %               index      a     b     c
            %               _______    __    __    __
            %             
            %               3          1     2     3
            %               4          4     5     6
            %               5          7     8     9
            %               6          1     2     3
            %               
            %
            
            response = obj.session_.mainAPI.getTabularData(obj.id_, varargin{:});
            data = struct2table(response.rows);
            
        end
        
    end
   
    methods (Static)
        function out = createFromResponse(resp, session)
            % CREATEFROMRESPONSE creates a tabular object form an API response.
            %
            content = resp.content;
            out = BFTabular(session, content.id, content.name, content.packageType);
            out.datasetId = content.datasetId;
            out.state = content.state;
        end
    end
    
end