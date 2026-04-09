function scal = calculate_screen_warp(config)
% CALCULATE_SCREEN_WARP Generate PsychoToolbox warp structure for screen correction
%
% This function generates the warp parameters needed by PsychoToolbox to correct
% visual stimuli displayed on a flat screen for spherical distortion when viewed
% from a fixed eye position. The calculation assumes the screen is tangential 
% to a sphere centered on the eye.
%
% This function should ONLY be called when generating warp files for PsychoToolbox.
% For calculating visual angles without warping, use calculate_viewing_angles() instead.
%
% Input:
%   config - Configuration struct from get_setup_config() with fields:
%            .w, .h, .d, .centre_w, .centre_h, .w_pix, .h_pix
%
% Output:
%   scal - Structure for PsychoToolbox warp containing:
%          .vcoords - viewport coordinates
%          .tcoords - texture coordinates for warp mapping
%          .screenNumber - screen number for PsychoToolbox
%          .useUnitDisplayCoords - coordinate system flag
%
% See also: calculate_viewing_angles, get_setup_config

% Get the visual angle mapping using the dedicated function
[x_angle_reg, y_angle_reg] = calculate_viewing_angles(config);

% Setup for warp calculation
centre_w_pix = config.w_pix * (config.centre_w / config.w);
centre_h_pix = config.h_pix * (config.centre_h / config.h);

% pixels at which to assess the warp
w_to_show = 1:10:config.w_pix+10;
h_to_show = 1:10:config.h_pix+10;

% two matrices with positions (similar to meshgrid)
X = repmat(w_to_show, length(h_to_show), 1);
Y = repmat(h_to_show', 1, length(w_to_show));

% recast these pixel positions in mm
X_mm = (X - centre_w_pix) * (config.w / config.w_pix);
Y_mm = (Y - centre_h_pix) * (config.h / config.h_pix);

% Calculate visual angles for each position
X_angle = atan(X_mm ./ sqrt(Y_mm.^2 + config.d^2));
Y_angle = atan(Y_mm ./ sqrt(X_mm.^2 + config.d^2));

% Create regular angular grid for lookup
[X_angle_reg, Y_angle_reg] = meshgrid(x_angle_reg, y_angle_reg);

% Find the closest element in the regular grid for each screen position
% This creates the mapping from regular angular space to screen pixels
X__ = nan(size(X_angle));
Y__ = nan(size(Y_angle));
for i = 1 : size(X_angle, 1)
    fprintf('Processing warp mapping: row %d of %d\n', i, size(X_angle, 1));
    for j = 1 : size(X_angle, 2)
        xdiff = (X_angle(i, j) - X_angle_reg).^2;
        ydiff = (Y_angle(i, j) - Y_angle_reg).^2;
        [~, idx] = min(xdiff(:) + ydiff(:));
        [row, col] = ind2sub(size(X_angle_reg), idx);
        X__(i, j) = col;
        Y__(i, j) = row;
    end
end

% Store the results in the PsychoToolbox warp structure
scal.vcoords = repmat(w_to_show, length(h_to_show), 1);
scal.vcoords(:, :, 2) = repmat(h_to_show', 1, length(w_to_show));
scal.tcoords = X__;
scal.tcoords(:, :, 2) = Y__;
scal.screenNumber = 1;
scal.useUnitDisplayCoords = false;

end
