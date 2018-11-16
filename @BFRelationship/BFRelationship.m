classdef BFRelationship < BFBaseSchemaNode
    % BFRELATIONSHIP  An object representing a relationship between models
    
    properties (Dependent)
        from    % Model ID 
        to
    end
    
    properties(Access = private)
        fromId 
        toId
    end
 
    methods
        function obj = BFRelationship(session, dataset, id, name, displayName, description, from, to)
            % BFRELATIONSHIP Constructor for objects of this class.
            
            obj = obj@BFBaseSchemaNode(session, dataset, id, name, displayName, description );
            obj.fromId = from;
            obj.toId = to;
        end
        
        function value = get.from(obj)
            allModelIds = {obj.dataset.models.id_};
            value = obj.dataset.models(strcmp(obj.fromId,allModelIds));
        end
        
        function value = get.to(obj)
            allModelIds = {obj.dataset.models.id_};
            value = obj.dataset.models(strcmp(obj.toId,allModelIds));
        end
        
    end
    
    methods (Static, Hidden)
        function out = createFromResponse(resp, session, dataset)
            % CREATEFROMRESPONSE creates object from server-response
            
            out = BFRelationship.empty(length(resp), 0);
            for i = 1:length(resp)
                curItem = resp(i);
                out(i) = BFRelationship(session, dataset, curItem.id, curItem.name, ...
                    curItem.displayName, curItem.description, curItem.from, curItem.to);

                out(i).setDates(curItem.createdAt, curItem.createdBy, curItem.updatedAt, ...
                    curItem.updatedBy);
            end

        end
    end
    

end