classdef SetupInfo < handle
    
    properties (SetAccess = private)
        ptb
    end
    
    properties
        screen_number
        screen_index
        distance_from_screen = 200
        screen_name
    end
    
    properties (Dependent = true)
        screen_size
        window
    end
    
    properties (SetAccess = private, Hidden = true)
        screen_pixels
        mm_per_pixel
        diagonal
        dst_rect
    end
    
    
    
    methods
        
        function obj = SetupInfo(ptb, screen_name, screen_number)
            obj.ptb = ptb;
            obj.screen_name = screen_name;
            VariableDefault('screen_number', max(obj.ptb.screens))
            obj.set_screen_number(screen_number);
            obj.screen_index = screen_number == obj.ptb.screens;
        end
        
        
        function val = get.screen_size(obj)
            val = screen_sizes(obj.screen_name);
        end
        
        function val = get.window(obj)
            val = obj.ptb.window(obj.screen_index);
        end
        
        
        function val = get_screen_pixels(obj)
            val = obj.ptb.screen_pixels();
            idx = obj.screen_number == obj.ptb.screens;
            val = val(idx, :);
        end
        
        
        function set_screen_number(obj, n)
            obj.screen_number = n;
            obj.screen_pixels = obj.get_screen_pixels();
            obj.mm_per_pixel = obj.get_mm_per_pixel();
            obj.diagonal = ceil(sqrt(sum(obj.screen_pixels.^2)));
        end
        
        
        function val = get_screen_half_angle(obj)
            val = (180/pi)*atan(obj.screen_size(1)/obj.distance_from_screen);
        end
        
        
        function val = get_mm_per_pixel(obj)
            val = (obj.screen_size ./ obj.screen_pixels);
        end
        
        
        function val = degrees_to_mm(obj, deg)
            val = 2 * obj.distance_from_screen * tan(deg2rad(deg)/2);
        end
    end
end