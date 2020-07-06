%% OPTIONS  GENERATE_SF_TF_SCHEDULE.M
% script to generate an experimental schedule for a set of
% directions/spatial/temporal frequencies, which can then be run as 
% multiple separate imaging sessions.


% where to save the experimental schedule information
schedule_file = 'sf_tf_rc2_20200706.mat';

type                    = 'DriftingGratings';
n_directions            = 8;  % number of directions of the stimuli to present
spatial_frequencies     = 0.01*2.^linspace(0, 4, 4);  % specify the spatial frequencies to present
temporal_frequencies    = [0.5, 1, 2, 4];   % specify the temporal frequencies to present
n_repetitions           = 5;  % number of repeats of all direction/SF/TF combinations
                              % if the sequence type is 'grey_static_drift_switch'
                              % then be careful here... it counts
                              % static-then-drift and drift-then-static as
                              % separate stimuli (so you have twice the
                              % number of stimuli)
n_stim_per_session      = 640;  % number of stimuli to present each time we press GRAB in Scanimage
                               % MUST DIVIDE n_directions * # spatial
                               % frequencies * # temporal frequencies * #
                               % n_repetitions.
n_baseline_triggers     = 4;  % the number of triggers to wait at the beginning and end of stimulus sequence
sequence                = 'drift_only';  % 'static_drift' = static grating followed by drifting grating of same dir/SF/TF
                                                % 'grey_static_drift' = put a grey screen between each stimulus
                                                % 'grey_static_drift_switch' =  grey screen before static/drift, but drift can come before static
                                                %                       again this is randomized
waveform                = 'sine';  % 'sine' or 'square'



%%
% Calculate directions (in degrees) from the number of directions specified
directions = linspace(0, 360, n_directions+1);
directions = directions(1:end-1);

% Create matrix with all combinations of direction, SF and TF.
[ori, sf, tf, drift_order] = ndgrid(directions, spatial_frequencies, temporal_frequencies, 2);
if strcmp(sequence, 'grey_static_drift_switch')
    [ori, sf, tf, drift_order] = ndgrid(directions, spatial_frequencies, temporal_frequencies, [1, 2]);
end


% Total number of stimuli is this 
n_stimuli = numel(ori) * n_repetitions;

% Make sure that the total number of stimuli is divisible by the number of
% stimuli per session.
assert(mod(n_stimuli, n_stim_per_session) == 0);

% Calculate the number of sessions we need.
n_sessions = n_stimuli / n_stim_per_session;

% Randomize the direction/SF/TF combinations for all repeats.
ori_ = [];
sf_ = [];
tf_ = [];
order_ = [];
for j = 1 : n_repetitions
    idx = randperm(numel(ori))';
    ori_ = cat(1, ori_, ori(idx));
    sf_ = cat(1, sf_, sf(idx));
    tf_ = cat(1, tf_, tf(idx));
    order_ = cat(1, order_, drift_order(idx));
end

if strcmp(sequence, 'drift_only')
    total_n_triggers = n_stim_per_session + 2*n_baseline_triggers;
elseif strcmp(sequence, 'static_drift')
    % 2 triggers per stimulus (static + drifting periods)
    % 2 baseline periods: one at beginning and one at end of stimulus
    % sequence
    total_n_triggers = 2*n_stim_per_session + 2*n_baseline_triggers;
elseif strcmp(sequence, 'grey_static_drift')
    % 3 triggers per stimulus (grey + static + drifting periods)
    % 2 baseline periods: one at beginning and one at end of stimulus
    % sequence
    total_n_triggers = 3*n_stim_per_session + 2*n_baseline_triggers;
elseif strcmp(sequence, 'grey_static_drift_switch')
    % 3 triggers per stimulus (grey + static + drifting periods)
    % 2 baseline periods: one at beginning and one at end of stimulus
    % sequence
    total_n_triggers = 3*n_stim_per_session + 2*n_baseline_triggers;
end

% Collect relevant information in a structure to save.
schedule.type                   = type;
schedule.n_directions           = n_directions;
schedule.directions             = reshape(ori_, n_stim_per_session, n_sessions);
schedule.spatial_frequencies    = reshape(sf_, n_stim_per_session, n_sessions);
schedule.temporal_frequencies   = reshape(tf_, n_stim_per_session, n_sessions);
schedule.start_phase            = 2*pi*rand(n_stim_per_session, n_sessions);
schedule.n_repetitions          = n_repetitions;
schedule.n_stim_per_session     = n_stim_per_session;
schedule.n_sessions             = n_sessions;
schedule.n_baseline_triggers    = n_baseline_triggers;
schedule.total_n_triggers       = total_n_triggers;
schedule.sequence               = sequence;
schedule.waveform               = waveform;
schedule.drift_order            = reshape(order_, n_stim_per_session, n_sessions);

% Save the schedule in specified location.
% If file exists, check before overwriting.
if exist(schedule_file, 'file')
    answer = questdlg('File name already exists. Overwrite?', '', 'Yes', 'No', 'No');
    if strcmp(answer, 'Yes')
        save(schedule_file, 'schedule');
    end
else
	save(schedule_file, 'schedule');
end

% clearup
clear all