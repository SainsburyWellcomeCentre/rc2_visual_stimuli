
% file where protocol is saved
prot_fname = 'sparse_noise_warped_rc2_20200302.mat';

% startup psychtoolbox
ptb                     = PsychoToolbox();
ptb.calibration_on      = false;

% warp info
ptb.warp_on             = true;
ptb.warp_file           = 'C:\Users\mateo\Documents\rc2\visstim\warp\warp_sony_projector.mat';

% load a gamma table for gamma correction
load('gamma/gamma_correction.mat');
ptb.gamma_table 	= gamma_table;

% which screen
screen_number           = 2;

% baseline time
baseline_duration       = 4;

% NI-DAQ info
nidaq_dev               = 'Dev1';
di_chan                 = 'port0/line0';


%% setup DAQ
di = daq.createSession('ni');
di.addDigitalChannel(nidaq_dev, di_chan, 'InputOnly');


% check that trigger is high to start
di_state = inputSingleScan(di);
if ~di_state
    error('Digital input should start high')
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

% create a square (or several)
sq                  = Square(ptb, []);


try
    
    % Startup psychtoolbox
    ptb.start(screen_number);
    
    % Present a grey screen.
    bck.buffer();
    ptb.flip();
    
    % Wait for trigger to go low.
    while inputSingleScan(di)
        % check for key-press from the user.
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape')), error('escape'), end
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



