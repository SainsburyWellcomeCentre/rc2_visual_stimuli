% Script for generating a file psychtoolbox can use for warping the
% stimulus.
% Script assumes screen is tangential to the sphere centred on the 
% eye

%% options

% filename to save warp parameters as
% we also pass this resulting mat file to psychtoolbox
fname = 'warp_wisecoco.mat';

% Get screen configuration from centralized screen_sizes function
[~, ~, config] = screen_sizes('wisecoco');

%% calculations

% Calculate warp parameters using shared function
[~, ~, scal] = calculate_screen_warp(config.w, config.h, config.d, ...
                                      config.centre_w, config.centre_h, ...
                                      config.w_pix, config.h_pix);

% warptype required for psychtoolbox
warptype = 'CSVDisplayList';

% Save the two structures
save(fname, 'warptype', 'scal')

