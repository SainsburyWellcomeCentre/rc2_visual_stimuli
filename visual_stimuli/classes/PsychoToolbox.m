classdef PsychoToolbox < handle
    
    properties (SetAccess = protected)
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
    
    properties (SetAccess = protected, Hidden =  true)
        screen_pixels
        white
        black
        mid_grey
        original_gamma
        active
        stereo  % boolean indicator if screen is stereo
        offscreen_left   % offscreen window for left eye
        offscreen_right  % offscreen window for right eye
        rotation_left    % rotation angle for left eye (degrees)
        rotation_right   % rotation angle for right eye (degrees)
        current_draw_window  % currently active draw window handle
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
            obj.stereo = false(1, length(obj.screens));
            obj.offscreen_left = nan(1, length(obj.screens));
            obj.offscreen_right = nan(1, length(obj.screens));
            obj.rotation_left = zeros(1, length(obj.screens));
            obj.rotation_right = zeros(1, length(obj.screens));
            obj.current_draw_window = nan(1, length(obj.screens));
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
            
            % Single PrepareConfiguration call
            PsychImaging('PrepareConfiguration');
            
            % Add warp/geometry correction if enabled
            if obj.warp_on && ~isempty(obj.warp_file)
                PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', obj.warp_file);
            end
            
            % Add display rotation
            PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
            
            % Now open the window
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

        function start_stereo(obj, screen_number, rotation_left, rotation_right)
            % START_STEREO Initialize PsychoToolbox in stereo mode with offscreen rendering
            %
            % Usage:
            %   ptb.start_stereo(screen_number)
            %   ptb.start_stereo(screen_number, rotation_left, rotation_right)
            %
            % Inputs:
            %   screen_number - Screen ID for PsychoToolbox
            %   rotation_left - (optional) Rotation angle in degrees for left eye (buffer 0), default: 0
            %   rotation_right - (optional) Rotation angle in degrees for right eye (buffer 1), default: 0
            %
            % Note: Always uses offscreen windows for rendering, which are copied to stereo
            %       buffers during flip with optional rotation applied.
            
            if nargin < 3, rotation_left = 0; end
            if nargin < 4, rotation_right = 0; end
            
            idx = screen_number == obj.screens;
            
            % Store rotation angles
            obj.rotation_left(idx) = rotation_left;
            obj.rotation_right(idx) = rotation_right;
            
            % Single PrepareConfiguration call
            PsychImaging('PrepareConfiguration');
            
            % Now open the window
            [win, win_rec] = PsychImaging('OpenWindow', screen_number, 0.001);
            obj.window(idx) = win;
            obj.window_rect(idx, :) = win_rec;
            
            % Create offscreen windows (one for each eye)
            % Each offscreen window is half the width of the full screen
            buffer_width = win_rec(3) / 2;
            buffer_height = win_rec(4);
            buffer_rect = [0, 0, buffer_width, buffer_height];
            
            obj.offscreen_left(idx) = Screen('OpenOffscreenWindow', screen_number, 0, buffer_rect);
            obj.offscreen_right(idx) = Screen('OpenOffscreenWindow', screen_number, 0, buffer_rect);
            
            % Set blend function for offscreen windows
            Screen('BlendFunction', obj.offscreen_left(idx), GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('BlendFunction', obj.offscreen_right(idx), GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            % Initialize current_draw_window to left eye
            obj.current_draw_window(idx) = obj.offscreen_left(idx);
            
            if obj.calibration_on
                obj.original_gamma{idx} = Screen('LoadNormalizedGammaTable', obj.window(idx), obj.gamma_table, 0);
            end
            
            Screen('BlendFunction', obj.window(idx), GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            obj.ifi = Screen('GetFlipInterval', obj.window(idx));
            obj.priority(idx) = MaxPriority(obj.window(idx));
            Priority(obj.priority(idx));
            Screen('Flip', obj.window(idx));
            obj.active(idx) = false;
            obj.stereo(idx) = true;
        end 

        function choose_eye(obj, screen_number, eye)
            % CHOOSE_EYE Select which eye buffer to draw to
            %
            % Usage:
            %   ptb.choose_eye(screen_number, 0)  % Select left eye
            %   ptb.choose_eye(screen_number, 1)  % Select right eye
            %
            % In stereo mode, this sets the current draw window to the appropriate
            % offscreen window. All subsequent drawing operations will target that window.
            
            idx = screen_number == obj.screens;
            if obj.stereo(idx)
                % Set current_draw_window to the appropriate offscreen window
                if eye == 0
                    obj.current_draw_window(idx) = obj.offscreen_left(idx);
                elseif eye == 1
                    obj.current_draw_window(idx) = obj.offscreen_right(idx);
                else
                    error('eye must be 0 (left) or 1 (right)');
                end
            else
                warning('can not choose eye on screen that is not stereo');
            end
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
            
            % Close offscreen windows if they exist
            for i = 1 : length(obj.screens)
                if ~isnan(obj.offscreen_left(i))
                    Screen('Close', obj.offscreen_left(i));
                end
                if ~isnan(obj.offscreen_right(i))
                    Screen('Close', obj.offscreen_right(i));
                end
            end
            
            Screen('CloseAll');
            sca;
            ShowCursor;
        end
        
        
        function flip(obj, screen_number)
            % FLIP Display the rendered content
            %
            % In stereo mode, this copies the offscreen windows to the stereo buffers
            % with rotation applied, then flips the display.
            
            idx = screen_number == obj.screens;
            
            if obj.stereo(idx)
                % Copy offscreen windows to stereo buffers with rotation
                win = obj.window(idx);
                
                % Get buffer dimensions
                win_rect = obj.window_rect(idx, :);
                buffer_width = win_rect(3) / 2;
                buffer_height = win_rect(4);
                
                % Define destination rectangles for left and right buffers
                left_dest_rect = [0, 0, buffer_width, buffer_height];
                right_dest_rect = [buffer_width, 0, win_rect(3), buffer_height];
                
                % Copy left eye with rotation
                Screen('DrawTexture', win, obj.offscreen_left(idx), [], left_dest_rect, obj.rotation_left(idx));
                
                % Copy right eye with rotation
                Screen('DrawTexture', win, obj.offscreen_right(idx), [], right_dest_rect, obj.rotation_right(idx));
            end
            
            % Flip the display
            Screen('Flip', obj.window(idx));
            
            % Clear offscreen windows for next frame
            if obj.stereo(idx)
                Screen('FillRect', obj.offscreen_left(idx), obj.mid_grey(idx));
                Screen('FillRect', obj.offscreen_right(idx), obj.mid_grey(idx));
            end
        end
    end
end