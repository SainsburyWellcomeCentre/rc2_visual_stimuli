classdef (Abstract) StimulusAbstract < handle
    
    properties (Abstract = true, Hidden = true, SetAccess = private)
        
        controller
    end
    
    
    
    methods (Abstract = true)
            
        prepare(obj)
        to_save(obj)
        run(obj)
    end
end


