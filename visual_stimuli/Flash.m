classdef Flash < handle
    
    properties
        
        n_baseline_triggers = 2
        n_flashes = 10
        pd_location = 'top_left'
    end
    
    
    properties (Hidden = true, Dependent = true)
        
        total_n_triggers
        pd_position
    end
    
    
    properties (Hidden = true)
        
        controller
    end
    
    
    
    methods
        
        function obj = Flash(controller)
            
            obj.controller = controller;
        end
        
        
        function val = get.total_n_triggers(obj)
            
            val = (2 * obj.n_baseline_triggers) + (2 * obj.n_flashes);
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
        
            
        function prepare(~)
            return
        end
        
        
        function val = to_save(obj)
            
            val.n_flashes = obj.n_flashes;
            val.n_baseline_triggers = obj.n_baseline_triggers;
            val.total_n_triggers = obj.total_n_triggers;
            
            val.pd_location = obj.pd_location;
            val.pd_position = obj.pd_position;
        end
        
        
        function run(obj)
            
            try
                sca;
                
                % Here we call some default settings for setting up Psychtoolbox
                PsychDefaultSetup(2);
                
                % Define black and white
                white = WhiteIndex(obj.controller.screen_number);
                black = BlackIndex(obj.controller.screen_number);
                
                % Open an on screen window
                [window, ~] = PsychImaging('OpenWindow', obj.controller.screen_number, black);
                
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
                
                for repIdx = 1 : obj.n_flashes
                    
                    for bwIdx = 1 : 2
                        
                        while inputSingleScan(obj.controller.daq.ctr) < (obj.n_baseline_triggers + triggerCount + 1)
                        
                            if bwIdx == 1
                                Screen('FillRect', window, white);
                            else
                                Screen('FillRect', window, black);
                            end
                        
                            % Flip to the screen on the next vertical retrace
                            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                        end
                        
                        triggerCount = triggerCount + 1;
                    end
                end
                
                Screen('FillRect', window, black)
                Screen('Flip', window);
                
                % Baseline frames at the end
                while inputSingleScan(obj.controller.daq.ctr) < obj.total_n_triggers
                end
                
                fprintf('Number of triggers expected: %i\n', obj.total_n_triggers)
                fprintf('Number of triggers received: %i\n', inputSingleScan(obj.controller.daq.ctr))
                
                % Setup and ready to go
                if obj.controller.socket_enabled
                    fprintf('waiting\n'), tic;
                    obj.controller.tcpip.wait_for_ready();
                    fprintf('finished, took %.2f\n', toc)
                else
                    pause(approx_trigger_interval)
                end
                
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


