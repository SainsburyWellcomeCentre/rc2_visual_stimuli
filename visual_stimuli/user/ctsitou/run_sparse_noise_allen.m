function run_sparse_noise_allen(session_n)


Screen('Preference', 'SkipSyncTests', 1);

% Specify stimulus type to get the correct options.
stim_type           = 'sparse_noise_allen';

% load the current run options
options             = general_options(stim_type);

% setup generic objects and structures
[ptb, setup, schedule] = general_setup(options);

% Create an object controlling the background
bck                 = Background(ptb);
bck.colour          = ptb.mid_grey_index(setup.screen_number);

% Create object controlling photodiode box
pd                  = Photodiode(ptb);

% Create a square
sq                  = Square(ptb, setup);

% Determine the location of each square
cols                = schedule.colours(:, session_n);
locs                = schedule.locations(:, session_n);
x_bounds            = schedule.x_bound;
y_bounds            = schedule.y_bound;
px_per_square       = schedule.px_per_square;

cols = [arrayfun(@(x)(ptb.mid_grey_index(setup.screen_number)), 1:schedule.n_baseline_triggers, 'uniformoutput', false)'; ...
        cols; ...
        arrayfun(@(x)(ptb.mid_grey_index(setup.screen_number)), 1:schedule.n_baseline_triggers, 'uniformoutput', false)';]; % ptb.mid_grey_index(setup.screen_number)
locs = [cell(schedule.n_baseline_triggers, 1); locs; cell(schedule.n_baseline_triggers, 1)];


% Make sure that the number of periods we've created is equal to the number
% of triggers in the schedule.
assert(length(locs) == schedule.total_n_triggers);


% Setup the data-acquisition hardware object
daq = VisualStimulusDAQ();

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
        while trigger_count < period + 1
            
            % Update the current stimulus and buffer it.
%             pos = grid.get_position(locs(period));
            pos = [x_bounds(locs{period}); y_bounds(locs{period});
                x_bounds(locs{period})+px_per_square(1); y_bounds(locs{period})+px_per_square(2)];
            
            %pos = [x_bounds(period), y_bounds(period), x_bounds(period)+px_per_square(1), y_bounds(period)+px_per_square(2)];
            sq.position = pos;
            sq.colour = repmat(cols{period}, 3, 1);
            sq.buffer();
            
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
                if toc(t) > 0.5
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
    % The pause is essential for logging the AI data to file.....
    pause(1)
    daq.stop();
    
catch ME
    
    ptb.stop();
    % The pause is essential for logging the AI data to file.....
    pause(1)
    daq.stop();
    
    % append information about the failure here.
    failure = trigger_count; %#ok<NASGU>
    msg = ME.message; %#ok<NASGU>
    if options.save_enabled
        save(fullfile(this_directory, 'stimulus_info.mat'), 'failure', 'msg', '-append')
    end
    
    rethrow(ME);
end






