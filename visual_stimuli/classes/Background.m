classdef Background < handle
    
    properties
        
        ptb
        colour = 0.1607;
    end
    
    methods
        
        function obj = Background(ptb)
            obj.ptb = ptb;
        end
        
        
        function initialize(~)
        end
        
        
        function buffer(obj)
            Screen('FillRect', obj.ptb.window, obj.colour);
        end
        
        
        function update(~)
        end
    end
end
        