classdef DriftingGratings < StimulusAbstract
    
    properties
        
        n_baseline_triggers = 2
        n_orientations = 8
        n_repetitions = 1
        pd_location = 'top_left'
        grey_or_static = 'static' % or 'grey'
        cycles_per_visual_degree = 0.025
        cycles_per_second = 2
    end
    
    
    properties (Hidden = true, Dependent = true)
        
        total_n_triggers
        pd_position
    end
    
    
    properties (Hidden = true, SetAccess = private)
        
        controller
        random_orientations
    end
    
    
    
    methods
        
        function obj = DriftingGratings(controller)
            
            obj.controller = controller;
        end
        
        
        function val = get.total_n_triggers(obj)
            
            val = 2 * obj.n_baseline_triggers + (2 * obj.n_orientations * obj.n_repetitions);
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
            
            % Get the orienations.
            orientations = linspace(0, 360, obj.n_orientations+1);
            orientations = orientations(1:obj.n_orientations);
            
            % Create a set of random positions and orientations.
            for repIdx = obj.n_repetitions : -1 : 1
                
                obj.random_orientations(repIdx, :) = orientations(randperm(length(orientations)));
            end
        end
        
        
        function val = to_save(obj)
            
            val.cycles_per_visual_degree = obj.cycles_per_visual_degree;
            val.cycles_per_second = obj.cycles_per_second;
            
            val.n_orientations = obj.n_orientations;
            val.n_repetitions = obj.n_repetitions;
            val.random_orientations = obj.random_orientations;
            val.n_baseline_triggers = obj.n_baseline_triggers;
            val.total_n_triggers = obj.total_n_triggers;
            val.grey_or_static = obj.grey_or_static;
            
            val.pd_location = obj.pd_location;
            val.pd_position = obj.pd_position;
        end
        
        
        function run(obj)
            
            try
                sca;
                
                [screen_pixels(1), screen_pixels(2)] = Screen('WindowSize', obj.controller.screen_number);
                
                mmPerPixel = obj.controller.screen_size./screen_pixels;
                
                % Shorthand for distance per visual angle at the centre of the screen
                mmPerVisualDegree = obj.controller.distance_from_screen * (pi/180);
                
                mmPerCycle = mmPerVisualDegree./obj.cycles_per_visual_degree;
                pixelsPerCycle = mmPerCycle./mmPerPixel;
                
                % Here we call some default settings for setting up Psychtoolbox
                PsychDefaultSetup(2);
                
                % Define black and white
                white = WhiteIndex(obj.controller.screen_number);
                black = BlackIndex(obj.controller.screen_number);
                grey = white / 2;
                
                % Open an on screen window
                [window, windowRect] = PsychImaging('OpenWindow', obj.controller.screen_number, grey);
                
                % Hide the cursor.
                HideCursor;
                
                % Get the size of the on screen window
                [screenXpixels, screenYpixels] = Screen('WindowSize', window);
                
                % Set up alpha-blending for smooth (anti-aliased) lines
                Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
                
                % Query the frame duration
                ifi = Screen('GetFlipInterval', window);
                
                % Grating size in pixels
                gratingSizePix = ceil(sqrt(screenXpixels^2 + screenYpixels^2));
                
                % Grating frequency in cycles / pixel
                freqCyclesPerPix = 1/pixelsPerCycle(1);
                
                % Define Half-Size of the grating image.
                texsize = gratingSizePix / 2;
                
                % First we compute pixels per cycle rounded to the nearest pixel
                pixPerCycle = ceil(1 / freqCyclesPerPix);
                
                % Frequency in Radians
                freqRad = freqCyclesPerPix * 2 * pi;
                
                % This is the visible size of the grating
                visibleSize = gratingSizePix;
                
                % Define our grating. Note it is only 1 pixel high. PTB will make it a full
                % grating upon drawing
                x = meshgrid(-texsize:texsize + pixPerCycle, 1);
                grating = round(grey * cos(freqRad*x) + grey);
                
                % Make a two layer mask filled with the background colour
                mask = ones(1, numel(x), 2) * white;
                
                % Contrast for our contrast modulation mask: 0 = mask has no effect, 1 = mask
                % will at its strongest part be completely opaque frameCounter.e. 0 and 100% contrast
                % respectively
                contrast = 1;
                
                % Place the grating in the 'alpha' channel of the mask
                mask(:, :, 2) = grating .* contrast;
                
                % Make our grating mask texture
                gratingMaskTex = Screen('MakeTexture', window, mask);
                
                % Make a black and white noise mask half the size of our grating. This will
                % be scaled upon drawing to make a "chunky" noise texture which our grating
                % will mask
                noise = round(ones(visibleSize)) .* black;
                
                % Make our noise texture
                noiseTex = Screen('MakeTexture', window, noise);
                
                % Make a destination rectangle for our textures and center this on the
                % screen
                dstRect = [0 0 visibleSize visibleSize];
                dstRect = CenterRect(dstRect, windowRect);
                
                % We set PTB to wait one frame before re-drawing
                waitframes = 1;
                
                % Calculate the wait duration
                waitDuration = waitframes * ifi;
                
                % Recompute pixPerCycle, this time without the ceil() operation from above.
                % Otherwise we will get wrong drift speed due to rounding errors
                pixPerCycle = 1 / freqCyclesPerPix;
                
                % Translate requested speed of the grating (in cycles per second) into
                % a shift value in "pixels per frame"
                shiftPerFrame = obj.cycles_per_second * pixPerCycle * waitDuration;
                
                % Sync us to the vertical retrace
                vbl = Screen('Flip', window);
                
                fprintf('Ready to start.\n')
                
                % Setup and ready to go
                if obj.controller.socket_enabled
                    obj.controller.tcpip.send_ready();
                end
                
                % Run a certain number of baseline frames at the beginning
                while inputSingleScan(obj.controller.daq.ctr) < obj.n_baseline_triggers + 1
                    if inputSingleScan(obj.controller.daq.ctr) == 1
                        tic;
                    end
                end
                
                % Calculate time since first trigger received and add 1
                % second to be sure.
                approx_trigger_interval = toc/obj.n_baseline_triggers + 1;
                
                triggerCount = 1;
                
                for repIdx = 1 : obj.n_repetitions
                    
                    for i = 1 : obj.n_orientations
                        
                        for staticIdx = 1 : 2
                            
                            % Set the frame counter to zero, we need this to 'drift' our grating
                            frameCounter = 0;
                            
                            while inputSingleScan(obj.controller.daq.ctr) < (obj.n_baseline_triggers + triggerCount + 1)
                                
                                if strcmp(obj.grey_or_static, 'static')
                                    
                                    if staticIdx == 1
                                        
                                        % Calculate the xoffset for our window through which to sample our
                                        % grating
                                        xoffset = mod(frameCounter * shiftPerFrame, pixPerCycle);
                                        
                                    else
                                        
                                        % Calculate the xoffset for our window through which to sample our
                                        % grating
                                        xoffset = mod(frameCounter * shiftPerFrame, pixPerCycle);
                                        % Now increment the frame counter for the next loop
                                        frameCounter = frameCounter + 1;
                                    end
                                    
                                    % Define our source rectangle for grating sampling
                                    srcRect = [xoffset, 0, xoffset + visibleSize, visibleSize];
                                    
                                    % Draw noise texture to the screen
                                    Screen('DrawTexture', window, noiseTex, [], dstRect, []);
                                    
                                    % Draw grating mask
                                    Screen('DrawTexture', window, gratingMaskTex, srcRect, dstRect, obj.random_orientations(repIdx, i));
                                    
                                    if staticIdx == 1
                                        Screen('FillRect', window, 0, obj.pd_position);
                                    else
                                        Screen('FillRect', window, 1, obj.pd_position);
                                    end
                                    
                                    % Flip to the screen on the next vertical retrace
                                    % vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                                    Screen('Flip', window);
                                    
                                else
                                    
                                    if staticIdx == 1
                                        
                                        % Calculate the xoffset for our window through which to sample our
                                        % grating
                                        Screen('FillRect', window, grey);
                                        Screen('FillRect', window, 0, obj.pd_position);
                                        
                                        % Flip to the screen on the next vertical retrace
                                        % vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                                        Screen('Flip', window);
                                    else
                                        
                                        % Calculate the xoffset for our window through which to sample our
                                        % grating
                                        xoffset = mod(frameCounter * shiftPerFrame, pixPerCycle);
                                        % Now increment the frame counter for the next loop
                                        frameCounter = frameCounter + 1;
                                        
                                        % Define our source rectangle for grating sampling
                                        srcRect = [xoffset, 0, xoffset + visibleSize, visibleSize];
                                        
                                        % Draw noise texture to the screen
                                        Screen('DrawTexture', window, noiseTex, [], dstRect, []);
                                        
                                        % Draw grating mask
                                        Screen('DrawTexture', window, gratingMaskTex, srcRect, dstRect, obj.random_orientations(repIdx, i));
                                        
                                        if staticIdx == 1
                                            Screen('FillRect', window, 0, obj.pd_position);
                                        else
                                            Screen('FillRect', window, 1, obj.pd_position);
                                        end
                                        
                                        % Flip to the screen on the next vertical retrace
                                        % vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                                        Screen('Flip', window);
                                    end
                                end
                            end
                            
                            triggerCount = triggerCount + 1;
                        end
                    end
                end
                
                Screen('FillRect', window, grey)
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
                fprintf('Here\n')
            end
            
        end
    end
end


