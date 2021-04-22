clear all;

% for testing spatial frequencies
test_on = false;

% file where protocol is saved
prot_fname = 'opticflow_rc2_20201214.mat';

if test_on
    %prot_fname = 'sf_tf_rc2_test.mat';
    is_waiting = true;
end

% variables
%% TODO need to save these data in a file somewhere, especially screen_position.

% Change the screen_position variable and unplug the other monitor, don't
% change screen_number.
screen_position         = 'right'; % 'left' or 'right';
screen_number           = 2;        % s
baseline_duration       = 10;        % s
drift_duration          = 2.5;      % s
isi_duration            = 2.5;      % s
distance_from_screen    = 100;       % mm
screen_name             = 'samsung_cfg73'; %'sony_projector';
wait_for_start_trigger  = false;  % wait for start trigger, true or false
gamma_correction_file   = 'gamma_correction_sony_projector.mat';

% NI-DAQ info
nidaq_dev               = 'Dev2';
di_chan                 = 'port0/line0';


% startup psychtoolbox
sca;
clear ptb;
ptb                     = PsychoToolbox();
ptb.calibration_on      = false;

% warp info
ptb.warp_on             = false;

% load a gamma table for gamma correction
load(gamma_correction_file, 'gamma_table');
ptb.gamma_table 	= gamma_table;

% Information about the setup.
setup                       = SetupInfo(ptb, screen_name, screen_number);
setup.distance_from_screen  = distance_from_screen;


%% setup DAQ
if wait_for_start_trigger
    
    di = daq.createSession('ni');
    di.addDigitalChannel(nidaq_dev, di_chan, 'InputOnly');

    di_state = inputSingleScan(di);
    
    % check that trigger is high to start
    di_state = inputSingleScan(di);
    if di_state
        error('Digital input should start low.')
    end

end

%% 
% load protocol
load(prot_fname, 'schedule');

%% 
% create an object controlling the background
bck                 = Background(setup);
bck.colour          = ptb.mid_grey_index(screen_number);

% create object controlling photodiode box
pd                  = Photodiode(setup);
if strcmp(screen_position, 'left')
    pd.location         = 'top_left';
else
    pd.location         = 'top_right';
end

% create object controlling binocular black spot
b_blank             = Blank_bino(setup);
if strcmp(screen_position, 'left')
    b_blank.location    = 'top_right';
else
    b_blank.location    = 'top_left';
end

% Create an object controlling the sequence of stimuli to present.
seq                 = Sequence();

for i = 1 : schedule.n_stim_per_session
    
    dg                   = DriftingGrating(setup);
    dg.waveform          = schedule.waveform;
    dg.cycles_per_degree = schedule.spatial_frequencies(i, 1);
    dg.cycles_per_second = schedule.temporal_frequencies(i, 1);
    dg.orientation       = schedule.directions(i, 1);
    dg.phase             = schedule.start_phase(i, 1);
    
    seq.add_period(dg);
end

n_stim_per_rep = schedule.n_stim_per_session / schedule.n_repetitions;
tic
try
    
    % Startup psychtoolbox
    ptb.start(screen_number);
    
    % initialize the sequences
    seq.initialize();
    
    % Present a grey screen.
    bck.buffer();
    ptb.flip(screen_number);
    
    % Wait for trigger to go low.
    if wait_for_start_trigger
        while inputSingleScan(di)
            % check for key-press from the user.
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape'), end
        end
    end
    
    for stim_i = 1 : schedule.n_stim_per_session + 1
        
        % white comes first
        % alternate the photodiode colour every stimulus.
        pd.colour = mod(stim_i+1, 2);
        
        if stim_i == (schedule.n_stim_per_session+1)
            pd.buffer();
            b_blank.buffer();
            ptb.flip(screen_number);
            
            pause(baseline_duration)
            break
        end
        
        if mod(stim_i-1, n_stim_per_rep) == 0
            ptb.flip(screen_number)
            pause(baseline_duration)
        end
        
        for frame_i = 1 : round(drift_duration/ptb.ifi)
            

             
            seq.period{stim_i}.update();
            seq.period{stim_i}.buffer();
            
            pd.buffer();
            b_blank.buffer();
            
            % Update the screen.
            ptb.flip(screen_number);
           
           
             
            % check for key-press from the user.
            if test_on
                while is_waiting
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(KbName('escape')), error('escape'), end
                    if keyCode(KbName('return')), is_waiting = false; end
                end
            else
                
                [~, ~, keyCode] = KbCheck;
                if keyCode(KbName('escape')), error('escape'), end
            end
        end
     
        if test_on
            % wait on next iteration
            is_waiting = true;
        end
        
        pd.buffer();
        b_blank.buffer();
        ptb.flip(screen_number);

        pause(isi_duration)
    end
    
    ptb.stop();
    
catch ME
    ptb.stop();
    rethrow(ME);
end
