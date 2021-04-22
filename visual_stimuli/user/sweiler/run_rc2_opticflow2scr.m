clear all;

test_on = false;

% file where protocol is saved
prot_fname = 'opticflow2scr_rc2_20201216';

if test_on
    %prot_fname = 'sf_tf_rc2_test.mat';
    is_waiting = true;
end
%% 



%PHYSICALLY CONNECT MONITOR A FIRST, THEN B, order is 3 and 2





%% 

% variables
%% TODO need to save these data in a file somewhere.
screen_numbers          = [3, 2];        % s
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
setup1                       = SetupInfo(ptb, screen_name, screen_numbers(1));
setup1.distance_from_screen  = distance_from_screen;

setup2                       = SetupInfo(ptb, screen_name, screen_numbers(2));
setup2.distance_from_screen  = distance_from_screen;


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
bck1                 = Background(setup1);
bck1.colour          = ptb.mid_grey_index(screen_numbers(1));

bck2                 = Background(setup2);
bck2.colour          = ptb.mid_grey_index(screen_numbers(2));

% create object controlling photodiode box
pd1                  = Photodiode(setup1);
pd1.location         = 'top_left';

pd2                  = Photodiode(setup2);
pd2.location         = 'top_right';

% create object controlling binocular black spot
b_blank1             = Blank_bino(setup1);
b_blank1.location    = 'top_right';

b_blank2             = Blank_bino(setup2);
b_blank2.location    = 'top_left';

% Create an object controlling the sequence of stimuli to present.
seq1                 = Sequence();
seq2                 = Sequence();

for i = 1 : schedule.n_stim_per_session

    dg1                   = DriftingGrating(setup1);
    dg1.waveform          = schedule.waveform;
    dg1.cycles_per_degree = schedule.spatial_frequencies(i, 1);
    dg1.cycles_per_second = schedule.temporal_frequencies(i, 1);
    dg1.orientation       = schedule.directions1(i, 1);
    dg1.phase             = schedule.start_phase(i, 1);
    
    seq1.add_period(dg1);
    
    dg2                   = DriftingGrating(setup2);
    dg2.waveform          = schedule.waveform;
    dg2.cycles_per_degree = schedule.spatial_frequencies(i, 1);
    dg2.cycles_per_second = schedule.temporal_frequencies(i, 1);
    dg2.orientation       = schedule.directions2(i, 1);
    dg2.phase             = schedule.start_phase(i, 1);
    
    seq2.add_period(dg2);
end

n_stim_per_rep = schedule.n_stim_per_session / schedule.n_repetitions;
tic
try
    
    % Startup psychtoolbox
    %sca;
    ptb.start(screen_numbers(1));
    ptb.start(screen_numbers(2));
    
    % initialize the sequences
    seq1.initialize();
    seq2.initialize();
    
    % Present a grey screen.
    bck1.buffer();
    bck2.buffer();
    ptb.flip(screen_numbers(1));
    ptb.flip(screen_numbers(2));
    
    % Wait for trigger to go high.
    if wait_for_start_trigger
        disp("Waiting for trigger.")
        while ~inputSingleScan(di)
            % check for key-press from the user.
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape'), end
        end
        disp("Triggered!")
    end
    

    
    for stim_i = 1 : schedule.n_stim_per_session + 1
            


        % white comes first
        % alternate the photodiode colour every stimulus.
        pd1.colour = mod(stim_i+1, 2);
        pd2.colour = mod(stim_i+1, 2);

        if stim_i == (schedule.n_stim_per_session+1)
            pd1.buffer();
            pd2.buffer();
            b_blank1.buffer();
            b_blank2.buffer();
            ptb.flip(screen_numbers(1));
            ptb.flip(screen_numbers(2));

            pause(baseline_duration)
            break;
        end

        if mod(stim_i-1, n_stim_per_rep) == 0
            ptb.flip(screen_numbers(1));
            ptb.flip(screen_numbers(2));
            pause(baseline_duration)
        end

        for frame_i = 1 : round(drift_duration/ptb.ifi)

            seq1.period{stim_i}.update();
            seq1.period{stim_i}.buffer();

            seq2.period{stim_i}.update();
            seq2.period{stim_i}.buffer();

            pd1.buffer();
            pd2.buffer();
            b_blank1.buffer();
            b_blank2.buffer();

            % Update the screen.
            ptb.flip(screen_numbers(1));
            ptb.flip(screen_numbers(2));


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
        
        pd1.buffer();
        pd2.buffer();
        b_blank1.buffer();
        b_blank2.buffer();
        ptb.flip(screen_numbers(1));
        ptb.flip(screen_numbers(2));

        pause(isi_duration)
        
    end
    
    ptb.stop();
    
catch ME
    ptb.stop();
    rethrow(ME);
end

toc
