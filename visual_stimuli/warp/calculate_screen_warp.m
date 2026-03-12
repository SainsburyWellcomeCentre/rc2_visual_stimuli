function [x_angle_reg, y_angle_reg, scal] = calculate_screen_warp(w, h, d, centre_w, centre_h, w_pix, h_pix)
% CALCULATE_SCREEN_WARP Compute warp parameters for spherical screen correction
%
% This function calculates warp parameters for correcting visual stimuli
% displayed on a flat screen to account for spherical distortion when viewed
% from a fixed eye position. The calculation assumes the screen is tangential 
% to a sphere centered on the eye.
%
% Inputs:
%   w - width of screen in mm
%   h - height of screen in mm
%   d - distance of eye from screen in mm
%   centre_w - horizontal position where eye is opposite (mm)
%   centre_h - vertical position where eye is opposite (mm)
%   w_pix - screen width in pixels
%   h_pix - screen height in pixels
%
% Outputs:
%   x_angle_reg - regular angular grid for x dimension (in radians)
%   y_angle_reg - regular angular grid for y dimension (in radians)
%   scal - structure for PsychoToolbox warp (optional, only computed if requested)
%          Contains vcoords and tcoords for warp mapping

centre_w_pix = w_pix*(centre_w/w);
centre_h_pix = h_pix*(centre_h/h);

% total angle in width and height of the screen
w_angle = 2*atan(w/(2*d));
h_angle = 2*atan(h/(2*d));

% pixels at which to assess the warp
w_to_show = 1:10:w_pix+10;
h_to_show = 1:10:h_pix+10;

% two matrices with positions (similar to meshgrid)
X = repmat(w_to_show, length(h_to_show), 1);
Y = repmat(h_to_show', 1, length(w_to_show));

% recast these pixel positions in mm
X_mm = (X-centre_w_pix)*(w/w_pix);
Y_mm = (Y-centre_h_pix)*(h/h_pix);

% for each position
% recast the x position to angle from centre vertical line
X_angle = atan(X_mm./sqrt(Y_mm.^2 + d^2));
% recast the y position to angle from centre vertical line
Y_angle = atan(Y_mm./sqrt(X_mm.^2 + d^2));
% NOTE: this angle is either the atan of opposite / adjacent side (X_mm/d) OR the
% asin of opposite side to hypothenuse (X_mm / sqrt( X_mm^2 + d^2))

% Resolution of the space in visual degrees
x_angle_reg = linspace(min(X_angle(:)), max(X_angle(:)), w_pix);
y_angle_reg = linspace(min(Y_angle(:)), max(Y_angle(:)), h_pix);

% Only compute full scal structure if requested (for PsychoToolbox warp files)
if nargout >= 3
    [X_angle_reg, Y_angle_reg] = meshgrid(x_angle_reg, y_angle_reg);
    
    % find the closest element
    X__ = nan(size(X_angle));
    Y__ = nan(size(Y_angle));
    for i = 1 : size(X_angle, 1)
        fprintf('Processing row %d of %d\n', i, size(X_angle, 1));
        for j = 1 : size(X_angle, 2)
            xdiff = (X_angle(i, j) - X_angle_reg).^2;
            ydiff = (Y_angle(i, j) - Y_angle_reg).^2;
            [~, idx] = min(xdiff(:) + ydiff(:));
            [row, col] = ind2sub(size(X_angle_reg), idx);
            X__(i, j) = col;
            Y__(i, j) = row;
        end
    end
    
    % Store the results in the required structure
    scal.vcoords = repmat(w_to_show, length(h_to_show), 1);
    scal.vcoords(:, :, 2) = repmat(h_to_show', 1, length(w_to_show));
    scal.tcoords = X__;
    scal.tcoords(:, :, 2) = Y__;
    scal.screenNumber = 1;
    scal.useUnitDisplayCoords = false;
end

end
