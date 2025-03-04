function this_directory = save_stimulus(stim_type, session_n, options, schedule, ptb, setup, pd, daq)

if ~options.save_enabled
    return
end


this_directory = create_directory(stim_type, session_n, options);

% store the latest commit in git
[~, stimulus.git_version] = system(sprintf('git --git-dir=%s rev-parse HEAD', options.git_dir));

% save the time the stimulus was run
stimulus.datetime = datetime;

% protocol specific parameters
if strcmp(stim_type, 'sparse_noise')
    stimulus.type                           = 'SparseNoise';
    stimulus.grid_size                      = schedule.grid_size;
    stimulus.stimulus.positions             = schedule.locations(:, session_n);
    stimulus.stimulus.colours               = schedule.colours(:, session_n);
    stimulus.stimulus.n_repetitions         = schedule.n_repetitions;
elseif strcmp(stim_type, 'sparse_noise_allen')
    stimulus.type                           = 'SparseNoiseAllen';
    stimulus.grid_size                      = schedule.grid_size;
    stimulus.stimulus.positions             = schedule.locations(:, session_n);
    stimulus.stimulus.colours               = schedule.colours(:, session_n);
    stimulus.stimulus.x_bound               = schedule.x_bound(:, session_n);
    stimulus.stimulus.y_bound               = schedule.y_bound(:, session_n);
    stimulus.stimulus.px_per_square         = schedule.px_per_square;
elseif strcmp(stim_type, 'sf_tf')
    stimulus.type                           = 'DriftingGratings';
    stimulus.stimulus.cycles_per_visual_degree = schedule.spatial_frequencies(:, session_n);
    stimulus.stimulus.cycles_per_second     = schedule.temporal_frequencies(:, session_n);
    stimulus.stimulus.directions            = schedule.directions(:, session_n);
    stimulus.stimulus.n_orientations        = schedule.n_directions;
    stimulus.stimulus.grey_or_static        = schedule.sequence;
    stimulus.stimulus.waveform              = schedule.waveform;
    stimulus.stimulus.n_repetitions         = schedule.n_repetitions;
elseif strcmp(stim_type, 'retinotopy')
    stimulus.type                           = 'Retinotopy';
    stimulus.grid_size                      = schedule.grid_size;
    stimulus.stimulus.positions             = schedule.locations(:, session_n);
    stimulus.stimulus.n_directions          = schedule.n_directions;
    stimulus.stimulus.drift_duration        = schedule.drift_duration;
    stimulus.stimulus.spatial_frequency     = schedule.spatial_frequency;
    stimulus.stimulus.temporal_frequency    = schedule.temporal_frequency;
    stimulus.stimulus.waveform              = schedule.waveform;
    stimulus.stimulus.n_repetitions         = schedule.n_repetitions;
end


stimulus.stimulus.n_baseline_triggers       = schedule.n_baseline_triggers;
stimulus.stimulus.total_n_triggers          = schedule.total_n_triggers;
stimulus.stimulus.pd_location               = pd.location;
stimulus.stimulus.pd_position               = pd.position;

% save the warp contents.
stimulus.stimulus.warp_on                   = ptb.warp_on;
if ptb.warp_on
    stimulus.stimulus.warp_contents         = load(ptb.warp_file);
else
    stimulus.stimulus.warp_contents         = [];
end


stimulus.source                             = options.schedule_file;
stimulus.schedule                           = schedule;
stimulus.session_n                          = session_n;
stimulus.n_stim_per_session                 = schedule.n_stim_per_session;
stimulus.distance_from_screen               = setup.distance_from_screen;
stimulus.n_triggers                         = schedule.total_n_triggers;
stimulus.screens                            = ptb.screens;
stimulus.screen_number                      = setup.screen_number;
stimulus.screen_size                        = setup.screen_size;


stimulus.daq.is_available                   = daq.is_available;
stimulus.daq.ai.device                      = daq.ai_device;
stimulus.daq.ai.channels                    = daq.channels;
stimulus.daq.ai.sample_rate                 = daq.sample_rate;
stimulus.daq.ai.save_every_n_samples        = daq.save_every_n_samples;
stimulus.daq.ai.save_directory              = daq.save_directory;
stimulus.daq.ctr.device                     = daq.counter_device;
stimulus.daq.ctr.channels                   = daq.counter_channel;
stimulus.daq.ai_min_voltage                 = daq.ai_min_voltage;
stimulus.daq.ai_max_voltage                 = daq.ai_max_voltage; %#ok<*STRNU>


save(fullfile(this_directory, 'stimulus_info.mat'), 'stimulus')





function val = create_directory(stim_type, session_n, options)

if ~options.save_enabled
    val = [];
    return
end

val = fullfile(options.save_dir, subdirectory(stim_type, session_n));

if isdir(val)
   answer = questdlg('Directory already exists. Continue?', '', 'Yes', 'No', 'No');
   if strcmp(answer, 'No')
       error('Aborting. Session likely aready run.')
   end
else
    mkdir(val)
end



function val = subdirectory(stim_type, session_n)
if strcmp(stim_type, 'sparse_noise')
    val = sprintf('sparse_noise_%03i', session_n);
elseif strcmp(stim_type, 'sparse_noise_allen')
    val = sprintf('sparse_noise_allen_%03i', session_n);
elseif strcmp(stim_type, 'sf_tf')
    val = sprintf('sf_tf_%03i', session_n);
elseif strcmp(stim_type, 'retinotopy')
    val = sprintf('retinotopy_%03i', session_n);
end