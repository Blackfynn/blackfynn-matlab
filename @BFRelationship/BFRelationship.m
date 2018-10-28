classdef BFRelationship < BFBaseSchemaNode
    % BFRELATIONSHIP  An object representing a relationship between models
    
    properties
        from
        to
    end
 
    methods
        
        function obj = BFRelationship(session, id, name, displayName, description, from, to)
            % BFRELATIONSHIP Constructor for objects of this class.
            
            obj = obj@BFBaseSchemaNode(session, id, name, displayName, description );
            obj.from = from;
            obj.to = to;
        end
        
    end
    
    methods (Static, Hidden)
        function out = createFromResponse(resp, session, dataset)
            % CREATEFROMRESPONSE creates object from server-response
            
            out = BFRelationship.empty(length(resp), 0);
            for i = 1:length(resp)
                curItem = resp(i);
                out(i) = BFRelationship(session, curItem.id, curItem.name, ...
                    curItem.displayName, curItem.description, curItem.from, curItem.to);

                out(i).setDates(curItem.createdAt, curItem.createdBy, curItem.updatedAt, ...
                    curItem.updatedBy);
                out(i).dataset = dataset;
            end

        end
    end
    

end