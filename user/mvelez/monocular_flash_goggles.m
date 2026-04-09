% monocular_flash_goggles - provide a series of short full monocular flash
% stimuli using the mouse_goggles setup
%
% Controls:
%   - ESC: Exit the script

Screen('Preference', 'SkipSyncTests', 1);

% Setup parameters
screen_number = 2;        % Psychtoolbox sees both goggles as one 800 x 400 screen
screen_name = 'wisecoco';

% NI-DAQ info
nidaq_dev               = 'Dev1';
di_experiment_started   = 'port0/line0';
wait_for_start_trigger  = true;  % wait for start trigger, true or false


% Initialize PsychoToolbox
ptb = PsychoToolbox();
ptb.calibration_on = false;
ptb.warp_on = false;

% Initialize SetupInfo
setup = SetupInfo(ptb, screen_name, screen_number, false);  % false = silent mode

% create an object controlling the background

white = ptb.white(screen_number);
black = ptb.black(screen_number);

bck                 = Background(setup);
bck.colour          = black;


% create object controlling photodiode box
pd                  = Photodiode(setup);
pd.location         = 'right_goggle_top_right';
pd.colour           = 'white';

%% Wait for start trigger

% Create DataAcquisition for digital input (trigger)
if wait_for_start_trigger
    dq_digital = daq("ni");
    addinput(dq_digital, nidaq_dev, di_experiment_started, "Digital");
    
    % Check that trigger is high to start
    initial_data = read(dq_digital);
    if initial_data{1, 1} ~= 1
        error('Digital input on channel 1 (experiment_started) should start high')
    end
end


%%
try
    % Start stereo mode with rotation
    % Left eye: 180 degrees, Right eye: 180 degrees
    ptb.start_stereo(screen_number, 90, 270);
    
    % ===== LEFT EYE (buffer 0) =====
    ptb.choose_eye(screen_number, 0);
    bck.colour = black;
    bck.buffer();

    % ===== RIGHT EYE (buffer 1) =====
    ptb.choose_eye(screen_number, 1);
    bck.colour = black;
    bck.buffer();
    
    ptb.flip(screen_number);
    
    % Wait for trigger to go low (high->low transition)
    if wait_for_start_trigger
        fprintf('Waiting for trigger (high->low)...\n');
        data = read(dq_digital);
        while data{1, 1} == 1
            pause(0.001);
            data = read(dq_digital);
        end
        fprintf('Trigger received!\n');
    end
    
    % Main display loop
    for i_flash = 1:40
        
        % pre flash baseline
        % ===== LEFT EYE (buffer 0) =====
        ptb.choose_eye(screen_number, 0);
        bck.colour = black;
        bck.buffer();

        % ===== RIGHT EYE (buffer 1) =====
        ptb.choose_eye(screen_number, 1);
        bck.colour = black;
        bck.buffer();
        
        ptb.flip(screen_number);
        WaitSecs(3);
        
        % emmit flash
        if mod(i_flash,2)==0
            % ===== LEFT EYE (buffer 0) =====
            ptb.choose_eye(screen_number, 0);
            bck.colour = white;
            bck.buffer();

            % ===== RIGHT EYE (buffer 1) =====
            ptb.choose_eye(screen_number, 1);
            bck.colour = black;
            bck.buffer();
        else
            % ===== LEFT EYE (buffer 0) =====
            ptb.choose_eye(screen_number, 0);
            bck.colour = black;
            bck.buffer();

            % ===== RIGHT EYE (buffer 1) =====
            ptb.choose_eye(screen_number, 1);
            bck.colour = white;
            bck.buffer();
        end
        %pd.buffer() % always show white photodiode indication of flash. This has the risk of inducing stray light artifact.
        ptb.flip(screen_number);
        WaitSecs(0.1);
                     
        % Check for ESC key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            break;
        end
        
 
    end
    
    % Clean up
    ptb.stop();
    fprintf('Test complete.\n');
    
catch ME
    % Error handling
    ptb.stop();
    rethrow(ME);
end




