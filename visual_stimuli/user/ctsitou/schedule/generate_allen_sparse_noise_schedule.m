%% OPTIONS  GENERATE_ALLEN_SPARSE_NOISE_SCHEDULE.M
% script to generate an experimental schedule for a set of
% sparse noise stimuli, which can then be run as  multiple separate 
% imaging sessions
%  THIS IS SPECIFICALLY FOR PROTOCOLS IN WHICH YOU WANT TO WARP THE
%  SPARSE NOISE. WE SPECIFY THE SPOTS IN TERMS OF VISUAL ANGLE, AND THUS THE
%  GRID SIZE IS DETERMINED BY THIS.

% where to save the experimental schedule information
schedule_file = 'sparse_noise_allen_schedule_20200212.mat';

type                    = 'SparseNoiseAllen';
square_size             = 4;    % visual degrees

screen_name             = 'samsung_cfg73';

[screen_size, screen_pix] = screen_sizes(screen_name);
distance_to_screen      = 200;

colours                 = [0, 1];  % colours to present ([0 = black, 1 = white])
n_sessions              = 5;        % number of sessions
n_stim_per_session      = 1600;      % number of these stimuli to present per session
n_baseline_triggers     = 40;       % the number of triggers to wait at the beginning and end of stimulus sequence
                                    % duration will be determined by the trigger interval used during acquisition


%%
% compute the number of squares we can fit on. We do this for one half of
% the screen, then multiply by 2 for the other half.

% max angle from midline to edge of the screen
% in horizontal and vertical
max_angle = (180/pi)*atan(screen_size/(2*distance_to_screen));

% size of the grid, given the size of each square
grid_size = 2*floor(max_angle/square_size);

% number of pixels per degree of visual angle
% we are presenting the squares to the screen before warping
% thus the screen becomes a space of visual angle
px_per_deg = (screen_pix/2)./max_angle;

% number of pixels for a single square in horizontal and vertical
px_per_square = square_size*px_per_deg;

% cell array to store the locations and colours of several squares
% each entry will be a vector containing the locations/colours to present each
% square
locations = cell(1, n_sessions*n_stim_per_session);
cols = cell(1, n_sessions*n_stim_per_session);

% the number of "pixels" to exclude around each dot
exclusion_zone = 5;

% a "stimulus" is a set of dots on the screen
% for each stimulus, create the array of dots
for i = 1 : n_sessions*n_stim_per_session
    
    grid_remaining = true(grid_size([2, 1])+2*exclusion_zone);
    
    [X, Y] = meshgrid(1:grid_size(1)+2*exclusion_zone, 1:grid_size(2)+2*exclusion_zone);
    
    valid_grid = ~grid_remaining;
    valid_grid(exclusion_zone+1:end-exclusion_zone, ...
        exclusion_zone+1:end-exclusion_zone) = 1;
    
    % while locations are still possible
    while sum(grid_remaining(:)) > 0
        % pick a index of the pixels still remaining
        idx = find(grid_remaining(:));
        I = randi(length(idx));
        this_pix = idx(I);
        
        % x, y location
        row = Y(this_pix);
        col = X(this_pix);
        
        % remove possible pixels around it
        to_remove = (X-col).^2 + (Y-row).^2 < exclusion_zone^2;
        grid_remaining(to_remove) = false;
        
        if valid_grid(this_pix)
            locations{i}(end+1) = (col-exclusion_zone-1)*grid_size(2) + (row-exclusion_zone);
            cols{i}(end+1) = randi(2)-1;
        end
    end
end

% sum over the squares
sum_squares = zeros(grid_size([2, 1]));
for i = 1 : n_sessions*n_stim_per_session
    sum_squares(locations{i}) = sum_squares(locations{i})+1;
end



% get the top/right-hand bounds of each square
lims = (screen_pix/2) - (grid_size/2).*px_per_square;
x_bound = lims(1) + (0:grid_size(1)-1)*px_per_square(1);
y_bound = lims(2) + (0:grid_size(2)-1)*px_per_square(2);

% 
[X_bound, Y_bound] = meshgrid(x_bound, y_bound);


% 1 trigger per stimulus
% 2 baseline periods: one at beginning and one at end of stimulus sequence
total_n_triggers = n_stim_per_session + 2*n_baseline_triggers;


% Collect relevant information in a structure to save.
schedule.type                   = type;
schedule.square_size            = square_size;
schedule.grid_size              = grid_size;
schedule.locations              = reshape(locations, n_stim_per_session, n_sessions);
schedule.colours                = reshape(cols, n_stim_per_session, n_sessions);
schedule.x_bound                = X_bound;
schedule.y_bound                = Y_bound;
schedule.px_per_square          = px_per_square;
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