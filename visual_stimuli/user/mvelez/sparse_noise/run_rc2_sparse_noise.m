
% file where protocol is saved
prot_fname = 'sparse_noise_warped_rc2_20200708.mat';

% variables
screen_number           = 2;        % s
baseline_duration       = 10;        % s
gamma_correction_file = 'gamma_correction_sony_projector.mat';
wait_for_start_trigger  = true;  % wait for start trigger, true or false

% NI-DAQ info
nidaq_dev               = 'Dev1';
di_chan                 = 'port0/line0';


% startup psychtoolbox
ptb                     = PsychoToolbox();
ptb.calibration_on      = true;

% warp info
ptb.warp_on             = true;
ptb.warp_file           = 'warp_sony_projector_300x180.mat';

% load a gamma table for gamma correction
load(gamma_correction_file, 'gamma_table');
ptb.gamma_table 	= gamma_table;


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

%% 
% load protocol
load(prot_fname, 'n_stimuli', 'x_border', 'y_border', ...
    'cols', 'x_locations', 'y_locations');

% create an object controlling the background
bck                 = Background(ptb);
bck.colour          = ptb.mid_grey_index(screen_number);

% create object controlling photodiode box
pd                  = Photodiode(ptb);
pd.location         = 'top_right';
pd.warp_style       = 'Polygon';

% create a square (or several)
sq                  = Square(ptb, []);


try
    
    % Startup psychtoolbox
    ptb.start(screen_number);
    
    % Present a grey screen.
    bck.buffer();
    ptb.flip();
    
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
            pd.buffer();
            ptb.flip()
            pause(baseline_duration)
            continue
        elseif stim_i == (n_stimuli+1)
            pd.buffer();
            ptb.flip();
            pause(baseline_duration)
            break
        end
        
        % update the current stimulus and buffer it.
        pos = [x_border(x_locations{stim_i}); y_border(y_locations{stim_i});
            x_border(x_locations{stim_i}+1); y_border(y_locations{stim_i}+1)];
        
        sq.position = pos;
        sq.colour = repmat(cols{stim_i}, 3, 1);
        sq.buffer();
        
        pd.buffer();
        
        % Update the screen.
        ptb.flip();
        
        % wait ~0.25s
        pause(0.25);
        
        % check for key-press from the user.
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape')), error('escape'), end
    end
    
    ptb.stop();
    
catch ME
    
    ptb.stop();
    rethrow(ME);
end



