classdef SparseNoise < handle
    
    properties
        
        n_baseline_triggers = 2
        n_repetitions = 1
        grid_size = [12, 10]
        pd_location = 'top_left'
    end
    
    
    properties (Hidden = true, Dependent = true)
        
        total_n_triggers
        pd_position
    end
    
    
    properties (Hidden = true, SetAccess = private)
        
        controller
        random_positions
        white_idx = 1
        black_idx = 2
    end
    
    
    
    methods
        
        function obj = SparseNoise(controller)
            
            obj.controller = controller;
        end
        
        
        function val = get.total_n_triggers(obj)
            
            val = 2 * obj.n_baseline_triggers + (2 * prod(obj.grid_size) * obj.n_repetitions);
        end
        
        
        function val = get.pd_position(obj)
            
            if strcmp(obj.pd_location, 'bottom_right')
                val = [1920-100, 1200-100, 1920, 1200];
            elseif strcmp(obj.pd_location, 'bottom_left')
                val = [0, 1200-100, 100, 1200];
            elseif strcmp(obj.pd_location, 'top_right')
                val = [1920-100, 0, 1920, 100];
            elseif strcmp(obj.pd_location, 'top_left')
                val = [0, 0, 200, 200];
            end
        end
        
            
        function prepare(obj)
            
            ordered_mtx(1, :) = [1:prod(obj.grid_size), 1:prod(obj.grid_size)];
            ordered_mtx(2, :) = [ones(1, prod(obj.grid_size)), 2*ones(1, prod(obj.grid_size))];
            
            % Create a set of random positions and orientations.
            obj.random_positions = nan(obj.n_repetitions, prod(obj.grid_size), 2);
            for repIdx = 1 : obj.n_repetitions
                rand_idx = randperm(2*prod(obj.grid_size));
                for posIdx = 1 : 2*prod(obj.grid_size)
                    obj.random_positions(repIdx, posIdx, :) = reshape(ordered_mtx(:, rand_idx(posIdx)), 1, 1, 2);
                end
            end
        end
        
        
        function val = to_save(obj)
            
            val.grid_size = obj.grid_size;
            val.n_baseline_triggers = obj.n_baseline_triggers;
            val.n_repetitions = obj.n_repetitions;
            val.total_n_triggers = obj.total_n_triggers;
            val.random_positions = obj.random_positions;
            val.white_idx = obj.white_idx;
            val.black_idx = obj.black_idx;
            
            val.pd_location = obj.pd_location;
            val.pd_position = obj.pd_position;
        end
        
        
        function run(obj)
            
            try
                % Clear the screen
                sca;
                
                % Get number of pixels on screen
                [screen_pixels(1), screen_pixels(2)] = Screen('WindowSize', obj.controller.screen_number);
                
                % Calculate the positions of the squares on the screen
                xSize = screen_pixels(1) / obj.grid_size(1);
                ySize = screen_pixels(2) / obj.grid_size(2);
                
                xCenter = xSize/2 : xSize : screen_pixels(1);
                yCenter = ySize/2 : ySize : screen_pixels(2);
                [xCenter, yCenter] = meshgrid(xCenter, yCenter);
                xCenter = xCenter(:);
                yCenter = yCenter(:);
                baseRect = [0, 0, xSize, ySize];
                
                % Here we call some default settings for setting up Psychtoolbox
                PsychDefaultSetup(2);
                
                % Define black, white and grey
                white = WhiteIndex(obj.controller.screen_number);
                black = BlackIndex(obj.controller.screen_number);
                grey = white / 2;
                
                % Open an on screen window
                [window, ~] = PsychImaging('OpenWindow', obj.controller.screen_number, grey);
                
                % Hide the cursor.
                HideCursor;
                
                % Set up alpha-blending for smooth (anti-aliased) lines
                Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
                
                % Query the frame duration
                ifi = Screen('GetFlipInterval', window);
                
                % We set PTB to wait one frame before re-drawing
                waitframes = 1;
                
                % Sync us to the vertical retrace
                vbl = Screen('Flip', window);
                
                fprintf('Ready to start.\n')
                
                % Setup and ready to go
                if obj.controller.socket_enabled
                    obj.controller.tcpip.send_ready();
                end
                
                tic;
                % Run a certain number of baseline frames at the beginning
                while inputSingleScan(obj.controller.daq.ctr) < obj.n_baseline_triggers + 1
                end
                
                approx_trigger_interval = toc/obj.n_baseline_triggers;
                
                triggerCount = 1;
                pd_alternator = 0;
                
                for repIdx = 1 : obj.n_repetitions
                    
                    for posIdx = 1 : 2*prod(obj.grid_size)
                        
                        current_position = obj.random_positions(repIdx, posIdx, 1);
                        current_color = obj.random_positions(repIdx, posIdx, 2);
                        
                        while inputSingleScan(obj.controller.daq.ctr) < (obj.n_baseline_triggers + triggerCount + 1)
                            
                            positionedRect = CenterRectOnPointd(baseRect, xCenter(current_position), yCenter(current_position));
                            
                            % Fill the screen with grey
                            Screen('FillRect', window, grey);
                            
                            % Get current color
                            if current_color == obj.white_idx
                                col = white;
                            elseif current_color == obj.black_idx
                                col = black;
                            end
                            
                            % Place square on screen in specified position.
                            Screen('FillRect', window, col, positionedRect);
                            
                            % Place square on screen for photodiode.
                            Screen('FillRect', window, pd_alternator, obj.pd_position);
                            
                            % Flip to the screen on the next vertical retrace
                            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                        end
                        
                        pd_alternator = mod(pd_alternator+1, 2);
                        triggerCount = triggerCount + 1;
                    end
                end
                
                Screen('FillRect', window, grey)
                Screen('Flip', window);
                
                % Baseline frames at the end
                while inputSingleScan(obj.controller.daq.ctr) < obj.total_n_triggers
                end
                
                fprintf('Number of triggers expected: %i\n', obj.total_n_triggers)
                fprintf('Number of triggers received: %i\n', inputSingleScan(obj.controller.daq.ctr))
                
                % Show gray screen till the end.
                pause(approx_trigger_interval)
                
                % Clear the screen
                sca;
                
                % Show the cursor.
                ShowCursor;
                
            catch ME
                sca;
                ShowCursor;
                rethrow(ME)
            end
        end
    end
end


