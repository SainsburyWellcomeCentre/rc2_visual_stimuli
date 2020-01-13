classdef PsychoToolbox < handle
    
    properties (SetAccess = private)
        screens
        window
        window_rect
        ifi
        priority
    end
    
    properties
        original_gamma
        gamma_table
        calibration_on = false
        warp_on = false
        warp_file
    end
    
    properties (SetAccess = private, Hidden =  true)
        screen_pixels
        white
        black
        mid_grey
    end
    
    
    
    methods
        
        function obj = PsychoToolbox()
            PsychDefaultSetup(2);
            obj.screens = Screen('Screens');
            [obj.screen_pixels, obj.white, obj.black, obj.mid_grey] = ...
                obj.get_screen_info();
        end
        
        
        function [sz, w_, b_, grey] = get_screen_info(obj)
            sz = nan(length(obj.screens), 2);
            w_ = nan(1, length(obj.screens));
            b_ = nan(1, length(obj.screens));
            grey = nan(1, length(obj.screens));
            for i = 1 : length(obj.screens)
                [sz(i, 1), sz(i, 2)] = Screen('WindowSize', obj.screens(i));
                w_(i) = WhiteIndex(obj.screens(i));
                b_(i) = BlackIndex(obj.screens(i));
                grey(i) = (w_(i) + b_(i))/2;
            end
        end
        
        
        function val = white_index(obj, screen_number)
            idx = screen_number == obj.screens;
            val = obj.white(idx);
        end
        
        
        function val = black_index(obj, screen_number)
            idx = screen_number == obj.screens;
            val = obj.black(idx);
        end
        
        
        function val = mid_grey_index(obj, screen_number)
            idx = screen_number == obj.screens;
            val = obj.mid_grey(idx);
        end
        
        function start(obj, screen_number)
            sca;
            HideCursor;
            
            if obj.warp_on && ~isempty(obj.warp_file)
                PsychImaging('PrepareConfiguration');
                PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', obj.warp_file);
            end
            
            [obj.window, obj.window_rect] = PsychImaging('OpenWindow', screen_number, 0.001);
            
            if obj.calibration_on
                obj.original_gamma = Screen('LoadNormalizedGammaTable', obj.window, obj.gamma_table, 0);
            end
            
            Screen('BlendFunction', obj.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            obj.ifi = Screen('GetFlipInterval', obj.window);
            obj.priority = MaxPriority(obj.window);
            Priority(obj.priority);
            Screen('Flip', obj.window);
        end
        
        
        function stop(obj)
            if obj.calibration_on && ~isempty(obj.original_gamma)
                Screen('LoadNormalizedGammaTable', obj.window, obj.original_gamma, 0);
            end
            Screen('CloseAll');
            sca;
            ShowCursor;
        end
        
        
        function flip(obj)
            Screen('Flip', obj.window);
        end
    end
end