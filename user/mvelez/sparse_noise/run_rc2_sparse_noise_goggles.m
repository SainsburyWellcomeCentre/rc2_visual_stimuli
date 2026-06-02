Screen('Preference', 'SkipSyncTests', 1);

% file where protocol is saved
prot_fname = 'sparse_noise_wisecoco_2500stims.mat';

% variables
screen_number           = 2;        % Psychtoolbox sees both goggles as one 800 x 400 screen with id 2
baseline_duration       = 10;        % s

% distance_from_screen is now loaded automatically from setup config
screen_name             = 'wisecoco';
gamma_correction_file   = 'C:\Users\mateo\Documents\rc2\visual_stimuli\visual_stimuli\gamma\gamma_table_wisecoco.mat';
wait_for_start_trigger  = true;  % wait for start trigger, true or false

% NI-DAQ info
nidaq_dev               = 'Dev1';
di_chan                 = 'port0/line0';
ao_chan                 = 'ao0';
ao_volt_white           = 5;
ao_volt_black           = 0;

% startup psychtoolbox
ptb                     = PsychoToolbox();
ptb.calibration_on      = false;

% warp info
ptb.warp_on             = false;
ptb.warp_file           = '';

% load a gamma table for gamma correction
load(gamma_correction_file, 'gamma_table');
ptb.gamma_table 	= gamma_table;


% SetupInfo now automatically loads distance_from_screen from config
setup                       = SetupInfo(ptb, screen_name, screen_number);

%% setup DAQ
if wait_for_start_trigger
    
    di = daq.createSession('ni');
    di.addDigitalChannel(nidaq_dev, di_chan, 'InputOnly');
    
    % check that trigger is high to start
    di_state = inputSingleScan(di);
    if ~di_state
        error('Digital input should start high')
    end
end

% add analog ouput to approximate photodiode
ao = daq.createSession('ni');
ao.addAnalogOutputChannel(nidaq_dev, ao_chan, 'Voltage');
ao_volt_grey = (ao_volt_white + ao_volt_black)/2;


%% 
% load protocol
load(prot_fname, 'n_stimuli', 'x_border', 'y_border', ...
    'cols', 'x_locations', 'y_locations');

% create an object controlling the background
bck                 = Background(setup);
bck.colour          = ptb.mid_grey_index(screen_number);

% create object controlling photodiode box
pd                  = Photodiode(setup);
pd.location         = 'right_goggle_top_right';

% create a square (or several)
sq                  = Square(ptb, setup);

%%
try
    
    % Startup psychtoolbox
    ptb.start_stereo(screen_number, 90, 270);
    ptb.choose_eye(screen_number, 0);

    % Present a grey screen.
    bck.buffer();
    ptb.flip(screen_number);
    
    % set analog output to grey value
    ao.outputSingleScan(ao_volt_grey);
    
    % Wait for trigger to go low.
    if wait_for_start_trigger
        while inputSingleScan(di)
            % check for key-press from the user.
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape'), end
        end
    end
    
    for stim_i = 0 : n_stimuli + 1
        
        % white comes first
        % alternate the photodiode colour every stimulus.
        pd.colour = mod(stim_i+1, 2);
       
        
        if stim_i == 0
            % handle one frame before stimulus onset
            pd.buffer();
            ptb.flip(screen_number);

            % set analog output to grey value
            ao.outputSingleScan(ao_volt_grey);
            pause(baseline_duration)
            continue
        
        elseif stim_i == (n_stimuli+1)
            % handle one frame after stimulus offset
            pd.buffer();
            ptb.flip(screen_number);
            % set analog output to grey value
            ao.outputSingleScan(ao_volt_grey);
            pause(baseline_duration)
            break
        end
        
        % switch analog output each stimulus between high and low    
        if mod(stim_i + 1, 2) == 0
            ao.outputSingleScan(ao_volt_black)
        else
            ao.outputSingleScan(ao_volt_white)
        end
        
        % update the current stimulus and buffer it.
        pos = [x_border(x_locations{stim_i}); y_border(y_locations{stim_i});
            x_border(x_locations{stim_i}+1); y_border(y_locations{stim_i}+1)];
        
        sq.position = pos;
        sq.colour = repmat(cols{stim_i}, 3, 1);
        
        
        ptb.choose_eye(screen_number, 0);
        sq.buffer();
        

        % Update the screen.
        pd.buffer();
        ptb.flip(screen_number);
        

        % wait ~0.25s
        pause(0.25);
        
        % check for key-press from the user.
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape')), error('escape'), end
    end
    
    ptb.stop();
    
    clear all
    
catch ME
    
    ptb.stop();
    clearvars -except ME
    rethrow(ME);
end