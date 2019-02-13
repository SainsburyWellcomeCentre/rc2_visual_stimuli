function run_retinotopy(session_n)
%%RUN_RETINOTOPY(session_number)
%   runs a

% Specify stimulus type to get the correct options.
stim_type = 'retinotopy';

% load the current run options
options             = general_options(stim_type);

% setup generic objects and structures
[ptb, setup, schedule] = general_setup(options);

% Create an object controlling the background
bck                 = Background(ptb);
bck.colour          = ptb.black_index(setup.screen_number);

% Create object controlling photodiode box
pd                  = Photodiode(ptb);

grid                = Grid(schedule.grid_size, [0, 0, setup.screen_pixels]);
transparency        = TransparentSquare(ptb, setup);

% Create an object controlling the sequence of gratings
seq                 = Sequence();

% Store grey screens in the first two periods.
for i = 1 : schedule.n_baseline_triggers
    seq.add_period(bck);
end
% Store a static grating, and then a drifting grating.
for i = 1 : schedule.n_stim_per_session
    dg                   = DriftingGrating(ptb, setup);
    dg.waveform          = schedule.waveform;
    dg.cycles_per_degree = schedule.spatial_frequency;
    dg.cycles_per_second = schedule.temporal_frequency;
    dg.orientation       = 0;
    dg.phase             = 0;
    
    seq.add_period(dg);
end
% Store grey screens in the last two periods.
for i = 1 : schedule.n_baseline_triggers
    seq.add_period(bck);
end

% Determine the location of each square
locs = schedule.locations(:, session_n);
locs = [ones(schedule.n_baseline_triggers, 1); locs; ones(schedule.n_baseline_triggers, 1)];

sz = grid.square_size();
transparency.position = round([0, 0, sz]);
transparency.colour = 0;

% Setup the data-acquisition hardware object
daq = VisualStimulusDAQ();

% Make sure that the number of periods we've created is equal to the number
% of triggers in the schedule.
assert(length(locs) == schedule.total_n_triggers);

% Save relevant information here, for each session
this_directory = save_stimulus(stim_type, session_n, options, schedule, ptb, setup, pd, daq);
if daq.is_available && options.save_enabled
    daq.save_ai = options.save_enabled;
    daq.save_directory = this_directory;
end


try
    
    trigger_count = 0;
    
    % Startup psychtoolbox
    ptb.start(setup.screen_number);
    
    % Start data acquisition logging.
    daq.start();
    
    % Initialize the gratings and transparency
    seq.initialize();
    transparency.initialize();
    
    % Present a grey screen.
    bck.buffer();
    ptb.flip();    
    
    % Wait for first trigger if daq is available, if not just wait for 2
    % seconds before starting.
    if daq.is_available
        while inputSingleScan(daq.ctr) < 1
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape'), end
        end
        trigger_count = inputSingleScan(daq.ctr);
    else
        pause(2);
        trigger_count = 1;
    end
    
    % calculate approximate intervals for last period.
    approx_interval = 2;
    interval_started = 0;
    
    for period = 1 : schedule.total_n_triggers
        
        t = tic;
        last_t = 0;
        
        while trigger_count < period + 1
            
            % Rotate the grating, and buffer.
            seq.period{period}.update();
            if mod(toc(t), schedule.drift_duration) < last_t && ~isa(seq.period{period}, 'Background')
                seq.period{period}.orientation = mod(seq.period{period}.orientation + 45, 360);
            end
            last_t = mod(toc(t), schedule.drift_duration);
            seq.period{period}.buffer();
            
            % Update the transparent square
            pos = grid.get_position(locs(period));
            transparency.position = round(pos);
            transparency.buffer();
            
            % Alternate the photodiode colour every trigger.
            pd.colour = mod(period, 2);
            pd.buffer();
            
            % Update the screen.
            ptb.flip();
            
            % Assess the condition for iterating to the next period
            %   trigger if it's available
            if daq.is_available
                trigger_count = inputSingleScan(daq.ctr);
            else
                if toc(t) > 4
                    trigger_count = trigger_count + 1;
                end
            end
            
            % on last period use the approximate interval calculated
            % earlier.
            if period == schedule.total_n_triggers
                if toc(t) > approx_interval
                    break
                end
            end
            
            % calculate approximate trigger interval between first and
            % second triggers.
            if period == 1 && interval_started == 0
            	t_interval = tic;
            	interval_started = 1;
            end
            if period == 2
                % add 1s to make sure we make it to the end.
                approx_interval = toc(t_interval) + 1;
            end
            
            % Check for key-press from the user.
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape'), end
        end
    end
    
    ptb.stop();
    
catch ME
    
    ptb.stop();
    
    % append information about the failure here.
    failure = trigger_count; %#ok<NASGU>
    msg = ME.message; %#ok<NASGU>
    save(fullfile(this_directory, 'stimulus_info.mat'), 'failure', 'msg', '-append')
    
    rethrow(ME);
end
