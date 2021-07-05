function varargout = screen_sizes(varargin)

monitor_names = {'dell_u2415b', 'hp_pavilion', 'samsung_cfg73', 'philips_278e', 'sony_projector', 'newdream8_240hz'};
screen_sizes = {[518.4, 324.0], [344, 193], [521.4, 293.3], [597.18, 337], [300, 180], [344, 193]};


% This will usually be the default screen size in pixels. We can of course change
% this in settings. If you want to do this, you can just create an extra
% entry here, and name the monitor something else.
screen_pixels = {[1920, 1200], [1366, 768], [1920, 1080], [1920, 1080], [1280, 720], [960, 540]};



if nargin == 1
    idx = strcmp(varargin{1}, monitor_names);
    varargout{1} = screen_sizes{idx};
    varargout{2} = screen_pixels{idx};
else
    fprintf('Stored monitors:\n');
    for i = 1 : length(monitor_names)
        fprintf(' %i:  %s\n', i, monitor_names{i});
    end
    return
end

if isempty(varargout{1})
    error('unrecognized screen name: %s', varargin{1});
end