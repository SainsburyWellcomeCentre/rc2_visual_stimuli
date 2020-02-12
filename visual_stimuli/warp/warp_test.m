%% Presents lines to the screen
%   
%   
%

Screen('Preference', 'SkipSyncTests', 1);

% Specify stimulus type to get the correct options.
screen_name                 = 'samsung_cfg73';
screen_number               = 1;
warp_on                     = true;
warp_file                   = 'warp\warp_samsung_cfg73.mat';


% width of the screen in mm
w = 521.4;
% height of the screen in mm
h = 293.3;
% distance of eye from the centre of the screen
d = 200;

% number of pixel width and height
w_pix = 1920;
h_pix = 1080;

% total angle in width and height of the screen
w_angle = rad2deg(2*atan(w/(2*d)));
h_angle = rad2deg(2*atan(h/(2*d)));

% create grid
im = ones(h_pix, w_pix);

x_scale = linspace(-w_angle/2, w_angle/2, w_pix);
y_scale = linspace(-h_angle/2, h_angle/2, h_pix);

degrees_to_plot = [0, 1, 5, 10, 20, 40];

for i = 1 : length(degrees_to_plot)
    [~, idx] = min(abs(x_scale - degrees_to_plot(i)));
    im(:, idx) = 0;
end

for i = 1 : length(degrees_to_plot)
    [~, idx] = min(abs(y_scale - degrees_to_plot(i)));
    im(idx, :) = 0;
end


ptb                         = PsychoToolbox();
ptb.warp_on                 = warp_on;
ptb.warp_file               = warp_file;


% Information about the setup.
setup                       = SetupInfo(ptb, screen_name);
setup.set_screen_number(screen_number);

try
    
    % Startup psychtoolbox
    ptb.start(setup.screen_number);
    
    texture_id = Screen('MakeTexture', ptb.window, im);
    Screen('DrawTexture', ptb.window, texture_id);
    Screen('Flip', ptb.window);
    
    tic
    while toc < 600
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape')); error('escape'); end
        %if keyCode(KbName('return')), is_waiting = 0; end
    end
    
    ptb.stop();
    
catch ME
    
    ptb.stop();
    rethrow(ME);
    
end
