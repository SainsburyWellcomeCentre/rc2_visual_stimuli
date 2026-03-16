classdef SetupInfo < handle
    
    properties (SetAccess = private)
        ptb
        config  % Stores full configuration from get_setup_config()
    end
    
    properties
        screen_number
        screen_index
        distance_from_screen
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
        
        function obj = SetupInfo(ptb, screen_name, screen_number, verbose)
            % SETUPINFO Create setup information object for stimulus presentation
            %
            % Usage:
            %   setup = SetupInfo(ptb, screen_name)
            %   setup = SetupInfo(ptb, screen_name, screen_number)
            %   setup = SetupInfo(ptb, screen_name, screen_number, verbose)
            %
            % Inputs:
            %   ptb - PsychoToolbox object
            %   screen_name - Setup name (e.g., 'mp_300', 'wisecoco')
            %   screen_number - (optional) Screen number for PsychoToolbox
            %   verbose - (optional) Show configuration details (default: true)
            
            obj.ptb = ptb;
            obj.screen_name = screen_name;
            
            % Load full configuration from JSON (with optional verbose output)
            if nargin < 4
                verbose = true;  % Default to showing configuration
            end
            obj.config = get_setup_config(screen_name, verbose);
            
            % Auto-populate viewing geometry from configuration
            obj.distance_from_screen = obj.config.d;
            
            % Set screen number
            VariableDefault('screen_number', max(obj.ptb.screens))
            obj.set_screen_number(screen_number);
            obj.screen_index = screen_number == obj.ptb.screens;
        end
        
        
        function val = get.screen_size(obj)
            % Get screen size from loaded configuration
            val = [obj.config.w, obj.config.h];
        end
        
        function val = get.window(obj)
            % GET.WINDOW Return the appropriate window handle for drawing
            %
            % In stereo mode, returns the current offscreen draw window.
            % In normal mode, returns the main window.
            
            if obj.ptb.stereo(obj.screen_index)
                % In stereo mode, return the current offscreen window
                val = obj.ptb.current_draw_window(obj.screen_index);
            else
                % In normal mode, return the main window
                val = obj.ptb.window(obj.screen_index);
            end
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
        
        
        function set.distance_from_screen(obj, val)
            % Allow manual override of distance, but warn if different from config
            if ~isempty(obj.config) && val ~= obj.config.d
                warning('SetupInfo:DistanceOverride', ...
                    'Manually setting distance_from_screen to %.1f mm (config has %.1f mm). Consider updating the setup configuration file if this is intentional.', ...
                    val, obj.config.d);
            end
            obj.distance_from_screen = val;
        end
    end
end