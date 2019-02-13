classdef Square < handle
    
    properties (SetAccess = private)
        ptb
        setup
    end
    
    properties
        position
        colour
    end
    
    methods
        
        function obj = Square(ptb, setup)
            obj.ptb = ptb;
            obj.setup = setup;
        end
        
        
        function buffer(obj)
            Screen('FillRect', obj.ptb.window, obj.colour, obj.position);
        end
    end
end
