classdef Photodiode < handle
    
    properties (SetAccess = private)
        ptb
        position
    end
    
    properties
        location = 'top_left'
        colour = 0;
    end
    
    methods
        
        function obj = Photodiode(ptb)
            obj.ptb = ptb;
        end
        
        
        
        function val = get.position(obj)
            switch obj.location
                case 'top_left'
                    val = [0, 0, 100, 100];
                case 'bottom_left'
                    val = [0, 950, 100, 1050];
                case 'bottom_right'
                    val = [1580, 950, 1680, 1050];
                case 'top_right'
                    val = [1580, 0, 1680, 100];
            end
        end
        
        
        
        function buffer(obj)
            Screen('FillRect', obj.ptb.window, obj.colour, obj.position);
        end
    end
end
