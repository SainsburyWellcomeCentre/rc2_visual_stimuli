% for testing spatial frequencies
test_on = true;

% file where protocol is saved
prot_fname = 'sf_tf_rc2_20200706.mat';

if test_on
    prot_fname = 'sf_tf_rc2_test.mat';
    is_waiting = true;
end

% variables
screen_number           = 2;        % s
baseline_duration       = 4;        % s
drift_duration          = 2.5;      % s
distance_from_screen    = 50;       % mm
screen_name             = 'sony_projector';
wait_for_start_trigger  = false;  % wait for start trigger, true or false
gamma_correction_file   = 'gamma_correction_sony_projector.mat';

% NI-DAQ info
nidaq_dev               = 'Dev1';
di_chan                 = 'port0/line0';


% startup psychtoolbox
ptb                     = PsychoToolbox();
ptb.calibration_on      = true;

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
    
    % check that trigger is high to start
    di_state = inputSingleScan(di);
    if ~di_state
        error('Digital input should start high')
    end
end

%% 
% load protocol
load(prot_fname, 'schedule');

% create an object controlling the background
bck                 = Background(ptb);
bck.colour          = ptb.mid_grey_index(screen_number);

% create object controlling photodiode box
pd                  = Photodiode(ptb);
pd.location         = 'top_right';

% Create an object controlling the sequence of stimuli to present.
seq                 = Sequence();

for i = 1 : schedule.n_stim_per_session
%     
%     g                   = Grating(ptb, setup);
%     g.waveform          = schedule.waveform;
%     g.cycles_per_degree = schedule.spatial_frequencies(i, session_n);
%     g.orientation       = schedule.directions(i, session_n);
%     g.phase             = schedule.start_phase(i, session_n);
    
    dg                   = DriftingGrating(ptb, setup);
    dg.waveform          = schedule.waveform;
    dg.cycles_per_degree = schedule.spatial_frequencies(i, 1);
    dg.cycles_per_second = schedule.temporal_frequencies(i, 1);
    dg.orientation       = schedule.directions(i, 1);
    dg.phase             = schedule.start_phase(i, 1);
    
    seq.add_period(dg);
end



try
    
    % Startup psychtoolbox
    ptb.start(screen_number);
    
    % initialize the sequences
    seq.initialize();
    
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
    
    for stim_i = 0 : schedule.n_stim_per_session + 1
        
        % white comes first
        % alternate the photodiode colour every stimulus.
        pd.colour = mod(stim_i+1, 2);
        
        if stim_i == 0
            pd.buffer();
            ptb.flip()
            pause(baseline_duration)
            continue
        elseif stim_i == (schedule.n_stim_per_session+1)
            pd.buffer();
            ptb.flip();
            pause(baseline_duration)
            break
        end
        
        for frame_i = 1 : round(drift_duration/ptb.ifi)
            
            seq.period{stim_i}.update();
            seq.period{stim_i}.buffer();
            
            pd.buffer();
            
            % Update the screen.
            ptb.flip();
            
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
    end
    
    ptb.stop();
    
catch ME
    ptb.stop();
    rethrow(ME);
end
