%% OPTIONS  GENERATE_SPARSE_NOISE_SCHEDULE.M
% script to generate an experimental schedule for a set of
% sparse noise stimuli, which can then be run as  multiple separate 
% imaging sessions where to save the experimental schedule information

% where to save the experimental schedule information
schedule_file = 'C:\data\ctsitou\CX_79_3\sparse_noise_schedule_20190219.mat';

type                    = 'SparseNoise';
grid_size               = [12, 10];  % locations to present sparse noise
colours                 = [0, 1];  % colours to present ([0 = black, 1 = white])
n_repetitions           = 10;  % number of repeats of all direction/SF/TF combinations
n_stim_per_session      = 480;  % MUST DIVIDE n_repetitions * grid_size(1) * grid_size(2)
n_baseline_triggers     = 4;  % the number of triggers to wait at the beginning and end of stimulus sequence



%%
% Create matrix with all combinations of location and colour.
[locations, col] = ndgrid(1:prod(grid_size), colours);

% Total number of stimuli is this 
n_stimuli = numel(locations) * n_repetitions;

% Make sure that the total number of stimuli is divisible by the number of
% stimuli per session.
assert(mod(n_stimuli, n_stim_per_session) == 0);

% Calculate the number of sessions we need.
n_sessions = n_stimuli / n_stim_per_session;

% Randomize the location/colour combinations for all repeats.
loc_ = [];
col_ = [];
for j = 1 : n_repetitions
    idx = randperm(numel(locations))';
    loc_ = cat(1, loc_, locations(idx));
    col_ = cat(1, col_, col(idx));
end

% 1 trigger per stimulus
% 2 baseline periods: one at beginning and one at end of stimulus sequence
total_n_triggers = n_stim_per_session + 2*n_baseline_triggers;


% Collect relevant information in a structure to save.
schedule.type                   = type;
schedule.grid_size              = grid_size;
schedule.locations              = reshape(loc_, n_stim_per_session, n_sessions);
schedule.colours                = reshape(col_, n_stim_per_session, n_sessions);
schedule.n_repetitions          = n_repetitions;
schedule.n_stim_per_session     = n_stim_per_session;
schedule.n_sessions             = n_sessions;
schedule.n_baseline_triggers    = n_baseline_triggers;
schedule.total_n_triggers       = total_n_triggers;

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