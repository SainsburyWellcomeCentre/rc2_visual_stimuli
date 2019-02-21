%% OPTIONS  GENERATE_SF_TF_SCHEDULE.M
% script to generate an experimental schedule for a set of
% directions/spatial/temporal frequencies, which can then be run as 
% multiple separate imaging sessions.


% where to save the experimental schedule information
schedule_file = 'C:\data\ctsitou\CX_79_3\sf_tf_schedule_20190219.mat';

type                    = 'DriftingGratings';
n_directions            = 8;  % number of directions of the stimuli to present
spatial_frequencies     = [0.01, 0.02, 0.04, 0.08, 0.16, 0.32];  % specify the spatial frequencies to present
temporal_frequencies    = [0.5, 1, 2, 4, 8, 16];   % specify the temporal frequencies to present
n_repetitions           = 9;  % number of repeats of all direction/SF/TF combinations
n_stim_per_session      = 48;  % number of stimuli to present each time we press GRAB in Scanimage
                               % MUST DIVIDE n_directions * # spatial
                               % frequencies * # temporal frequencies * #
                               % n_repetitions.
n_baseline_triggers     = 4;  % the number of triggers to wait at the beginning and end of stimulus sequence
sequence                = 'static_drift';  % 'static_drift' = static grating followed by drifting grating of same dir/SF/TF
waveform                = 'sine';  % 'sine' or 'square'



%%
% Calculate directions (in degrees) from the number of directions specified
directions = linspace(0, 360, n_directions+1);
directions = directions(1:end-1);

% Create matrix with all combinations of direction, SF and TF.
[ori, sf, tf] = ndgrid(directions, spatial_frequencies, temporal_frequencies);

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
for j = 1 : n_repetitions
    idx = randperm(numel(ori))';
    ori_ = cat(1, ori_, ori(idx));
    sf_ = cat(1, sf_, sf(idx));
    tf_ = cat(1, tf_, tf(idx));
end

if strcmp(sequence, 'static_drift')
    % 2 triggers per stimulus (static + drifting periods)
    % 2 baseline periods: one at beginning and one at end of stimulus
    % sequence
    total_n_triggers = 2*n_stim_per_session + 2*n_baseline_triggers;
end

% Collect relevant information in a structure to save.
schedule.type                   = type;
schedule.n_directions           = n_directions;
schedule.directions             = reshape(ori_, n_stim_per_session, n_sessions);
schedule.spatial_frequencies    = reshape(sf_, n_stim_per_session, n_sessions);
schedule.temporal_frequencies   = reshape(tf_, n_stim_per_session, n_sessions);
schedule.n_repetitions          = n_repetitions;
schedule.n_stim_per_session     = n_stim_per_session;
schedule.n_sessions             = n_sessions;
schedule.n_baseline_triggers    = n_baseline_triggers;
schedule.total_n_triggers       = total_n_triggers;
schedule.sequence               = sequence;
schedule.waveform               = waveform;

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