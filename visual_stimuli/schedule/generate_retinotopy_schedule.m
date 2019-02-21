%% OPTIONS  GENERATE_RETINOTOPY_SCHEDULE.M
% script to generate an experimental schedule for a retinotopy 

% where to save the experimental schedule information
schedule_file = 'C:\data\ctsitou\CX_79_3\retinotopy_schedule_20190219.mat';

type                    = 'Retinotopy';
grid_size               = [4, 3];  % locations to present sparse noise, [x, y]
n_repetitions           = 10;  % number of repeats of all direction/SF/TF combinations
n_stim_per_session      = 120;  % number of stimuli to present each time we press GRAB in Scanimage
                                % MUST DIVIDE n_repetitions * grid_size(1) * grid_size(2)
n_baseline_triggers     = 4;  % the number of triggers to wait at the beginning and end of stimulus sequence

waveform                = 'square';  % 'sine' or 'square'
n_directions            = 8;  % number of directions the grating moves in
drift_duration          = 0.5;  % number of seconds which each orientation drifts for
spatial_frequency       = 0.04; % spatial frequency of the grating
temporal_frequency      = 2;  % temporal frequency of the grating


%%
% Create matrix with all combinations of direction, SF and TF.
locations = 1:prod(grid_size);

% Total number of stimuli is this 
n_stimuli = numel(locations) * n_repetitions;

% Make sure that the total number of stimuli is divisible by the number of
% stimuli per session.
assert(mod(n_stimuli, n_stim_per_session) == 0);

% Calculate the number of sessions we need.
n_sessions = n_stimuli / n_stim_per_session;

% Randomize the locations for all repeats.
loc_ = [];
for j = 1 : n_repetitions
    idx = randperm(numel(locations))';
    loc_ = cat(1, loc_, locations(idx));
end

% 1 trigger per position
% 2 baseline periods: one at beginning and one at end of stimulus sequence
total_n_triggers = n_stim_per_session + 2*n_baseline_triggers;


% Collect relevant information in a structure to save.
schedule.type                   = type;
schedule.grid_size              = grid_size;
schedule.locations              = reshape(loc_, n_stim_per_session, n_sessions);
schedule.n_directions           = n_directions;
schedule.n_repetitions          = n_repetitions;
schedule.n_stim_per_session     = n_stim_per_session;
schedule.n_sessions             = n_sessions;
schedule.n_baseline_triggers    = n_baseline_triggers;
schedule.total_n_triggers       = total_n_triggers;
schedule.drift_duration         = drift_duration;
schedule.spatial_frequency      = spatial_frequency;
schedule.temporal_frequency     = temporal_frequency;
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