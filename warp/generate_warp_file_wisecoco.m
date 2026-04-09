% Script for generating a file psychtoolbox can use for warping the
% stimulus.
% Script assumes screen is tangential to the sphere centred on the 
% eye

%% options

% filename to save warp parameters as
% we also pass this resulting mat file to psychtoolbox
fname = 'warp_wisecoco.mat';

% Get setup configuration (verbose output shows screen details)
config = get_setup_config('wisecoco', true);

%% calculations

% Generate PsychoToolbox warp structure
scal = calculate_screen_warp(config);

% warptype required for psychtoolbox
warptype = 'CSVDisplayList';

% Save the two structures
save(fname, 'warptype', 'scal')

