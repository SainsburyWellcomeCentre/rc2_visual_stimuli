function varargout = screen_sizes(varargin)

monitor_names = {'mp_300', 'wisecoco'};

% Physical screen dimensions [width, height] in mm
screen_sizes = {[347, 195.6], [35.3, 35.3]};

% This will usually be the default screen size in pixels. We can of course change
% this in settings. If you want to do this, you can just create an extra
% entry here, and name the monitor something else.
screen_pixels = {[960, 540], [400, 400]};

% Distance from eye to screen in mm (for warp calculations)
% Empty means no warp parameters available for this screen
eye_distance = {150, 12};

% Eye center position [centre_w, centre_h] in mm (for warp calculations)
% Empty means screen center should be used
eye_centre = {[150, 25], [35.3/2, 35.3/2]};


if nargin == 0
    fprintf('Stored monitors:\n');
    for i = 1 : length(monitor_names)
        fprintf(' %i:  %s\n', i, monitor_names{i});
    end
    return
end

if nargin == 1
    idx = strcmp(varargin{1}, monitor_names);
    
    if ~any(idx)
        error('unrecognized screen name: %s', varargin{1});
    end
    
    % Return screen size (backward compatible)
    varargout{1} = screen_sizes{idx};
    
    % Return screen pixels if requested (backward compatible)
    if nargout >= 2
        varargout{2} = screen_pixels{idx};
    end
    
    % Return full config struct if requested (NEW)
    if nargout >= 3
        config.name = monitor_names{idx};
        config.w = screen_sizes{idx}(1);
        config.h = screen_sizes{idx}(2);
        config.w_pix = screen_pixels{idx}(1);
        config.h_pix = screen_pixels{idx}(2);
        config.d = eye_distance{idx};
        config.centre_w = [];
        config.centre_h = [];
        
        if ~isempty(eye_centre{idx})
            config.centre_w = eye_centre{idx}(1);
            config.centre_h = eye_centre{idx}(2);
        end
        
        varargout{3} = config;
    end
end