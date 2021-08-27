clear all

%% options
% screen name
screen_name = 'mp_300';

% where to save to
save_fname = 'sparse_noise_warped_mp_300_20210827.mat';

% number of stimuli
n_stimuli = 2500;

square_size = 5; % deg

% width of the screen in mm
w = 347;
% height of the screen in mm
h = 195;
% distance of eye from the screen
d = 80;

% location on screen of closest point to eye
centre_w = 80;
centre_h = h-25;

% number of pixel width and height
w_pix = 960;
h_pix = 540;



%% calculations

centre_w_pix = w_pix*(centre_w/w);
centre_h_pix = h_pix*(centre_h/h);

% total angle in width and height of the screen
w_angle = 2*atan(w/(2*d));
h_angle = 2*atan(h/(2*d));

% pixles at which to assess the warp
w_to_show = 1:10:w_pix+10;
h_to_show = 1:10:h_pix+10;


% relabel these matrices
X = repmat(w_to_show, length(h_to_show), 1);
Y = repmat(h_to_show', 1, length(w_to_show));

% recast these pixel positions in mm
X_mm = (X-centre_w_pix)*(w/w_pix);
Y_mm = (Y-centre_h_pix)*(h/h_pix);

% For each position
% recast the x position to angle from centre vertical line
X_angle = atan(X_mm./sqrt(Y_mm.^2 + d^2));
% recast the y position to angle from centre vertical line
Y_angle = atan(Y_mm./sqrt(X_mm.^2 + d^2));

% Resolution of the space in visual degrees
x_angle_reg = linspace(min(X_angle(:)), max(X_angle(:)), w_pix);
y_angle_reg = linspace(min(Y_angle(:)), max(Y_angle(:)), h_pix);

% square info
pix_square      = deg2rad(square_size);

% number of x and y squares
n_x             = floor(range(x_angle_reg)/pix_square);
n_y             = floor(range(y_angle_reg)/pix_square);

% borders of the squares in visual degree space
x_border = linspace(0.5, w_pix-0.5, n_x+1);
y_border = linspace(0.5, h_pix-0.5, n_y+1);




%% create noise
% cell array to store the locations and colours of several squares
% each entry will be a vector containing the locations/colours to present each
% square
locations       = cell(1, n_stimuli);
x_locations     = cell(1, n_stimuli);
y_locations     = cell(1, n_stimuli);
cols            = cell(1, n_stimuli);

% the number of "pixels" to exclude around each dot
exclusion_zone  = 5;
grid_size       = [n_y, n_x];

% reseed
rng(1);

% a "stimulus" is a set of dots on the screen
% for each stimulus, create the array of dots
for i = 1 : n_stimuli
    i
    grid_remaining = true(grid_size + 2*exclusion_zone);
    
    [X, Y] = meshgrid(1:grid_size(2) + 2*exclusion_zone, 1:grid_size(1) + 2*exclusion_zone);
    
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
        
        % if pixel is in valid region save its location
        if valid_grid(this_pix)
            locations{i}(end+1) = (col-exclusion_zone-1)*grid_size(1) + (row-exclusion_zone);
            [y_locations{i}(end+1), x_locations{i}(end+1)] = ind2sub(grid_size, locations{i}(end));
            cols{i}(end+1) = randi(2)-1;
        end
    end
end

% save all variables
save(save_fname);
