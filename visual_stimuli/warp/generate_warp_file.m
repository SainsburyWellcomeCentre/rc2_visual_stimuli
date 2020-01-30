% Script for generating a file psychtoolbox can use for warping the
% stimulus.
% Whole script assumes screen is tangential to the sphere centred on the 
% eye, and nearest point to the eye is the centre of the screen)


% filename to save warp parameters as
% we also pass this resulting mat file to psychtoolbox
fname = 'warp_philips_278e_2.mat';

% width of the screen in mm
w = 597.12;%368;
% height of the screen in mm
h = 335.88;%203;
% distance of eye from the centre of the screen
d = 200;

% number of pixel width and height
w_pix = 1920;%1366;
h_pix = 1080;%768;

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
X_mm = (X-w_pix/2)*(w/w_pix);
Y_mm = (Y-h_pix/2)*(h/h_pix);

% for each position
% recast the x position to angle from centre vertical line
X_angle = atan(X_mm./sqrt(Y_mm.^2 + d^2));
% recast the y position to angle from centre vertical line
Y_angle = atan(Y_mm./sqrt(X_mm.^2 + d^2));

% This indicates which X pixels should be sent to the orignal pixel location
% above
X__ = (X_angle + w_angle/2)*(w_pix/w_angle);
% This indicates which Y pixels should be sent to the original pixel
% location above
Y__ = (Y_angle + h_angle/2)*(h_pix/h_angle);

% Store the results in the required structure
scal.tcoords = X__;
scal.tcoords(:, :, 2) = Y__;

% also required for psychtoolbox
warptype = 'CSVDisplayList';

% Save the two structures
save(fname, 'warptype', 'scal')

