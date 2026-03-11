classdef Background < handle
    
    properties
        
        setup
        colour = 0.1607;

    end
    
    methods
        
        function obj = Background(setup)
            obj.setup = setup;
        end
        
        
        function initialize(~)
        end
        
        
        function buffer(obj)
            Screen('OpenWindow', obj.setup.window, obj.colour);
        end
        
        
        function update(~)
        end
    end
end
        