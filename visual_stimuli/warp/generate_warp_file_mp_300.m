% Script for generating a file psychtoolbox can use for warping the
% stimulus.
% Script assumes screen is tangential to the sphere centred on the 
% eye

%% options

% filename to save warp parameters as
% we also pass this resulting mat file to psychtoolbox
fname = 'warp_mp_300.mat';

% width of the screen in mm
w = 347;
% height of the screen in mm
h = 195;
% distance of eye from the centre of the screen
d = 80;

% where mouse eye is opposite
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
%  
w_to_show = 1:10:w_pix+10;
h_to_show = 1:10:h_pix+10;

% two matrices with positions (similar to meshgrid)
scal.vcoords = repmat(w_to_show, length(h_to_show), 1);
scal.vcoords(:, :, 2) = repmat(h_to_show', 1, length(w_to_show));

% relabel these matrices
X = scal.vcoords(:, :, 1);
Y = scal.vcoords(:, :, 2);

% recast these pixel positions in mm
X_mm = (X-centre_w_pix)*(w/w_pix);
Y_mm = (Y-centre_h_pix)*(h/h_pix);

% for each position
% recast the x position to angle from centre vertical line
X_angle = atan(X_mm./sqrt(Y_mm.^2 + d^2));
% recast the y position to angle from centre vertical line
Y_angle = atan(Y_mm./sqrt(X_mm.^2 + d^2));

% This indicates which X pixels should be sent to the orignal pixel location
% above
% So we have our pixel location on the screen (x0, y0), and we want to know
% which "entry" of the regular angle grid gets sent to the this pixel.
x_angle_reg = linspace(min(X_angle(:)), max(X_angle(:)), w_pix);
y_angle_reg = linspace(min(Y_angle(:)), max(Y_angle(:)), h_pix);
[X_angle_reg, Y_angle_reg] = meshgrid(x_angle_reg, y_angle_reg);

% find the closest element
X__ = nan(size(X_angle));
Y__ = nan(size(Y_angle));
for i = 1 : size(X_angle, 1)
    i
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
scal.tcoords = X__;
scal.tcoords(:, :, 2) = Y__;

% also required for psychtoolbox
warptype = 'CSVDisplayList';

scal.screenNumber = 1;
scal.useUnitDisplayCoords = false;

% Save the two structures
save(fname, 'warptype', 'scal')

