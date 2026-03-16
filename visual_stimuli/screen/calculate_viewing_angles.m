function [x_angle_rad, y_angle_rad, angles_info] = calculate_viewing_angles(config)
% CALCULATE_VIEWING_ANGLES Compute visual angles covered by screen from eye position
%
% This function calculates the angular range of the visual field covered by
% a flat screen when viewed from a fixed eye position. This is pure geometry
% calculation and is independent of any display warping.
%
% Input:
%   config - Configuration struct with fields:
%            .w - width of screen in mm
%            .h - height of screen in mm  
%            .d - distance of eye from screen in mm
%            .centre_w - horizontal position where eye is opposite (mm)
%            .centre_h - vertical position where eye is opposite (mm)
%            .w_pix - screen width in pixels
%            .h_pix - screen height in pixels
%
% Outputs:
%   x_angle_rad - 1D array of angular positions in horizontal dimension (radians)
%   y_angle_rad - 1D array of angular positions in vertical dimension (radians)
%   angles_info - (optional) struct with detailed angular coverage information:
%                 .x_range_rad - total horizontal angular range (radians)
%                 .y_range_rad - total vertical angular range (radians)
%                 .x_range_deg - total horizontal angular range (degrees)
%                 .y_range_deg - total vertical angular range (degrees)
%                 .x_min_deg, x_max_deg - horizontal angular bounds (degrees)
%                 .y_min_deg, y_max_deg - vertical angular bounds (degrees)

centre_w_pix = config.w_pix * (config.centre_w / config.w);
centre_h_pix = config.h_pix * (config.centre_h / config.h);

% pixels at which to assess the angular mapping
w_to_show = 1:10:config.w_pix+10;
h_to_show = 1:10:config.h_pix+10;

% Create coordinate matrices
X = repmat(w_to_show, length(h_to_show), 1);
Y = repmat(h_to_show', 1, length(w_to_show));

% Convert pixel positions to mm
X_mm = (X - centre_w_pix) * (config.w / config.w_pix);
Y_mm = (Y - centre_h_pix) * (config.h / config.h_pix);

% Calculate visual angles from eye position
% X angle: horizontal angle from center vertical line
X_angle = atan(X_mm ./ sqrt(Y_mm.^2 + config.d^2));
% Y angle: vertical angle from center horizontal line  
Y_angle = atan(Y_mm ./ sqrt(X_mm.^2 + config.d^2));

% Create regular angular grids spanning the screen's angular range
x_angle_rad = linspace(min(X_angle(:)), max(X_angle(:)), config.w_pix);
y_angle_rad = linspace(min(Y_angle(:)), max(Y_angle(:)), config.h_pix);

% Populate optional detailed info output
if nargout >= 3
    angles_info.x_range_rad = range(x_angle_rad);
    angles_info.y_range_rad = range(y_angle_rad);
    angles_info.x_range_deg = rad2deg(angles_info.x_range_rad);
    angles_info.y_range_deg = rad2deg(angles_info.y_range_rad);
    angles_info.x_min_deg = rad2deg(min(x_angle_rad));
    angles_info.x_max_deg = rad2deg(max(x_angle_rad));
    angles_info.y_min_deg = rad2deg(min(y_angle_rad));
    angles_info.y_max_deg = rad2deg(max(y_angle_rad));
end

end
