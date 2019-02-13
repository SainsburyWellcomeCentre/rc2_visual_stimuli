classdef TransparentSquare < handle
    
    properties (SetAccess = private)
        ptb
        setup
    end
    
    properties
        position
        colour
        mask_texture
    end
    
    properties (Dependent = true)
        size
    end
    
    
    methods
        
        function obj = TransparentSquare(ptb, setup)
            obj.ptb = ptb;
            obj.setup = setup;
        end
        
        
        function val = get.size(obj)
            val = obj.position([3, 4]) - obj.position([1, 2]);
        end
        
        
        function initialize(obj)
            sz = 2*obj.setup.screen_pixels - obj.size;
            starts = obj.setup.screen_pixels - obj.size;
            mask = 255 * ones([sz(2), sz(1), 2]);
            mask(:, :, 1) = obj.colour * mask(:, :, 1);
            mask(starts(2) + (1:obj.size(2)), starts(1) + (1:obj.size(1)), 2) = 0;
            mask = uint8(mask);
            obj.mask_texture = Screen('MakeTexture', obj.ptb.window, mask);
        end
        
        
        function buffer(obj)
            sz = 2*obj.setup.screen_pixels - obj.size;
            d = CenterRect([0, 0, sz], obj.position);
            Screen('DrawTexture', obj.ptb.window, obj.mask_texture, [], d);
        end
    end
end
