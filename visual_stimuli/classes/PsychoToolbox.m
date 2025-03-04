classdef PsychoToolbox < handle
    
    properties (SetAccess = private)
        screens
        window
        window_rect
        ifi
        priority
    end
    
    properties
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
        original_gamma
        active
    end
    
    
    
    methods
        
        function obj = PsychoToolbox()
            PsychDefaultSetup(2);
            obj.screens = Screen('Screens');
            [sz, w_, b_, grey] = obj.get_screen_info();
            
            obj.screen_pixels = sz;
            obj.white = w_;
            obj.black = b_;
            obj.mid_grey = grey;
            
            obj.window = nan(1, length(obj.screens));
            obj.window_rect = nan(length(obj.screens), 4);
            obj.ifi = nan(1, length(obj.screens));
            obj.priority = nan(1, length(obj.screens));
            obj.original_gamma = cell(1, length(obj.screens));
            obj.active = false(1, length(obj.screens));
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
            % Can't clear screens here if there are multiple screens.
            %sca;
            % Turn off hide cursor for now because it's annoying during
            % development.
            %HideCursor;
            
            idx = screen_number == obj.screens;
            
            if obj.warp_on && ~isempty(obj.warp_file)
                PsychImaging('PrepareConfiguration');
                PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', obj.warp_file);
            end
            
            %[obj.window, obj.window_rect] = PsychImaging('OpenWindow', screen_number, 0.001);
            [win, win_rec] = PsychImaging('OpenWindow', screen_number, 0.001);
            obj.window(idx) = win;
            obj.window_rect(idx, :) = win_rec;
            
            if obj.calibration_on
                obj.original_gamma{idx} = Screen('LoadNormalizedGammaTable', obj.window(idx), obj.gamma_table, 0);
            end
            
            Screen('BlendFunction', obj.window(idx), GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            obj.ifi = Screen('GetFlipInterval', obj.window(idx));
            obj.priority(idx) = MaxPriority(obj.window(idx));
            Priority(obj.priority(idx));
            Screen('Flip', obj.window(idx));
            obj.active(idx) = false;
        end
        
        
        function stop(obj)
            
            if obj.calibration_on
                for i = 1 : length(obj.screens)
                    if obj.active(i) && ~isempty(obj.original_gamma{i})
                        Screen('LoadNormalizedGammaTable', obj.window(i), obj.original_gamma{i}, 0);
                        obj.active(i) = false;
                    end
                end
            end
            
            Screen('CloseAll');
            sca;
            ShowCursor;
        end
        
        
        function flip(obj, screen_number)
            
            
            idx = screen_number == obj.screens;
            
            Screen('Flip', obj.window(idx));

        end
    end
end