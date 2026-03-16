% flicker goggles - Minimal test script for design of the photodiode
% flicker signal
%
% Controls:
%   - ESC: Exit the script

Screen('Preference', 'SkipSyncTests', 1);

% Setup parameters
screen_number = 2;        % Psychtoolbox sees both goggles as one 800 x 400 screen
screen_name = 'wisecoco';

% Initialize PsychoToolbox
ptb = PsychoToolbox();
ptb.calibration_on = false;
ptb.warp_on = false;

% Initialize SetupInfo
setup = SetupInfo(ptb, screen_name, screen_number, false);  % false = silent mode

% create an object controlling the background
bck                 = Background(setup);
bck.colour          = ptb.mid_grey_index(screen_number);

%% create a polygon just covering the footprint of the photodiode
screen_radius = 200; % px
top_right = screen_radius/sqrt(2) * [1 -1] + [200 200];
photodiode_mm = [4 2.5];
mm_to_px = 400/37;
photodiode_px = photodiode_mm * mm_to_px;
theta = pi/4; % 45 deg
rot_mat = [
    [cos(theta) -sin(theta)];
    [sin(theta) cos(theta)];
    ];
center_to_edge_vectors = [
    [ -photodiode_px(1) -photodiode_px(2)];
    [  photodiode_px(1) -photodiode_px(2)];
    [  photodiode_px(1)  photodiode_px(2)];
    [ -photodiode_px(1)  photodiode_px(2)];
    ]/2;
center_to_edge_rotated = rot_mat * center_to_edge_vectors';

photodiode_polygon = top_right + center_to_edge_rotated';


%%
try
    % Start stereo mode with rotation
    % Left eye: 180 degrees, Right eye: 180 degrees
    ptb.start_stereo(screen_number, 90, 270);
    
    frame_i = 0;
    % Main display loop
    while true
        
        % ===== LEFT EYE (buffer 0) =====
        
        ptb.choose_eye(screen_number, 0);
        colour = 1.0*mod(frame_i, 2);
        Screen('FillPoly',setup.window, colour, photodiode_polygon);
       
        % ===== RIGHT EYE (buffer 1) =====
        colour = 1.0*mod(frame_i+1, 2);
        pd_rect.colour = colour;
        
        ptb.choose_eye(screen_number, 1);
        colour = 1.0*mod(frame_i+1, 2);
        Screen('FillPoly',setup.window, colour, photodiode_polygon);
        
        % Flip to display both buffers (will apply rotation automatically)
        ptb.flip(screen_number);
        
        frame_i = frame_i + 1;
        
        % Check for ESC key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            break;
        end
        
        % Short pause to prevent excessive CPU usage
        WaitSecs(0.25);
    end
    
    % Clean up
    ptb.stop();
    fprintf('Test complete.\n');
    
catch ME
    % Error handling
    ptb.stop();
    rethrow(ME);
end


