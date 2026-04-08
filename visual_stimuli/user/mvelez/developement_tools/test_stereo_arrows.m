% TEST_STEREO_ARROWS - Minimal test script for displaying arrows on both stereo buffers
%
% This script demonstrates basic stereo display using the wisecoco goggles.
% It draws to arrows pointing up and right on both goggles
% Up is white on both goggles, right is red on the left and blue on the
% right screen.
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

try
    % Start stereo mode with rotation
    % Left eye: 180 degrees, Right eye: 180 degrees
    ptb.start_stereo(screen_number, 90, 270);
    
    % Get window rectangles for centering
    win_rect = ptb.window_rect(screen_number == ptb.screens, :);
    buffer_width = win_rect(3) / 2;  % Each eye gets half width in stereo mode
    buffer_height = win_rect(4);
    [centerX, centerY] = RectCenter([0, 0, buffer_width, buffer_height]);
    
    % Define arrow size
    arrow_size = 100;  % pixels
    
    fprintf('Displaying stereo arrows with rotation. Press ESC to exit.\n');
    fprintf('Left eye: 180° rotation, Right eye: 180° rotation\n');
    
    % Main display loop
    while true
        % ===== LEFT EYE (buffer 0) =====
        ptb.choose_eye(screen_number, 0);
        win_left = setup.window;
        
        % Clear to grey
        Screen('FillRect', win_left, ptb.mid_grey_index(screen_number));
        
        % Draw white arrow pointing up
        arrow_color_white = [255, 255, 255];  % White
        draw_arrow(win_left, centerX, centerY, arrow_size, 'up', arrow_color_white);
        % Draw red arrow pointing right
        arrow_color_red = [255, 0, 0];  % Red
        draw_arrow(win_left, centerX, centerY, arrow_size, 'right', arrow_color_red);
       
        % ===== RIGHT EYE (buffer 1) =====
        ptb.choose_eye(screen_number, 1);
        win_right = setup.window;

        
        % Clear to grey
        Screen('FillRect', win_right, ptb.mid_grey_index(screen_number));
        
        % Draw white arrow pointing up
        draw_arrow(win_right, centerX, centerY, arrow_size, 'up', arrow_color_white);
        % Draw blue arrow pointing right
        arrow_color_blue = [0, 0, 255];  % Blue
        draw_arrow(win_right, centerX, centerY, arrow_size, 'right', arrow_color_blue);
        
       
        % Flip to display both buffers (will apply rotation automatically)
        ptb.flip(screen_number);
        
        % Check for ESC key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            break;
        end
        
        % Short pause to prevent excessive CPU usage
        WaitSecs(0.01);
    end
    
    % Clean up
    ptb.stop();
    fprintf('Test complete.\n');
    
catch ME
    % Error handling
    ptb.stop();
    rethrow(ME);
end


%% Helper function to draw an arrow
function draw_arrow(win, centerX, centerY, size, direction, color)
    % DRAW_ARROW Draw a simple arrow on the screen
    %
    % Inputs:
    %   win - Window pointer
    %   centerX, centerY - Center position
    %   size - Arrow size in pixels
    %   direction - 'left', 'right', 'up', or 'down'
    %   color - RGB triplet [R, G, B]
    
    % Arrow proportions
    shaft_width = size * 0.3;
    shaft_length = size * 0.6;
    head_width = size * 0.6;
    head_length = size * 0.4;
    
    % Define arrow pointing right (will rotate for other directions)
    % Arrow body (shaft)
    shaft_rect = [0, -shaft_width/2, shaft_length, shaft_width/2];
    
    % Arrow head (triangle)
    head_x = [shaft_length, shaft_length + head_length, shaft_length];
    head_y = [-head_width/2, 0, head_width/2];
    
    % Rotate arrow based on direction
    switch lower(direction)
        case 'right'
            angle = 0;
        case 'left'
            angle = 180;
        case 'up'
            angle = -90;
        case 'down'
            angle = 90;
        otherwise
            angle = 0;
    end
    
    % Apply rotation
    angle_rad = deg2rad(angle);
    cos_a = cos(angle_rad);
    sin_a = sin(angle_rad);
    
    % Rotate shaft corners
    shaft_corners = [
        shaft_rect(1), shaft_rect(3), shaft_rect(3), shaft_rect(1);
        shaft_rect(2), shaft_rect(2), shaft_rect(4), shaft_rect(4)
    ];
    
    rotated_shaft = [
        cos_a * shaft_corners(1,:) - sin_a * shaft_corners(2,:);
        sin_a * shaft_corners(1,:) + cos_a * shaft_corners(2,:)
    ];
    
    % Rotate head
    rotated_head = [
        cos_a * head_x - sin_a * head_y;
        sin_a * head_x + cos_a * head_y
    ];
    
    % Translate to center position
    shaft_final = rotated_shaft + [centerX; centerY];
    head_final = rotated_head + [centerX; centerY];
    
    % Draw shaft (rectangle)
    Screen('FillPoly', win, color, shaft_final', 1);
    
    % Draw head (triangle)
    Screen('FillPoly', win, color, head_final', 1);
end
