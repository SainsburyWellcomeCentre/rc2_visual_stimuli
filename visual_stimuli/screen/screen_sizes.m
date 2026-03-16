function varargout = screen_sizes(varargin)
% SCREEN_SIZES - DEPRECATED: Use get_setup_config() instead
%
% This function is maintained for backward compatibility only.
% New code should use get_setup_config() which provides the same
% functionality with clearer naming and additional features.
%
% Legacy usage:
%   size = screen_sizes(name)           % Returns [width, height] in mm
%   [size, pixels] = screen_sizes(name) % Also returns pixel resolution
%   [size, pixels, config] = screen_sizes(name) % Also returns full config struct
%   screen_sizes()                      % Lists available setups
%
% Recommended new usage:
%   config = get_setup_config(name)     % Returns full config struct with verbose output
%
% See also: get_setup_config

% Issue deprecation warning on first call (only once per session)
persistent warning_issued;
if isempty(warning_issued)
    warning('screen_sizes:deprecated', ...\n            'screen_sizes() is deprecated. Use get_setup_config() instead for clearer API and verbose output.');
    warning_issued = true;
end

% If called with no arguments, list available setups
if nargin == 0
    get_setup_config();  % This will print the list
    return
end

% Get the configuration using the new function (silently)
config = get_setup_config(varargin{1}, false);

% Return outputs in the legacy format for backward compatibility
if nargout >= 1
    varargout{1} = [config.w, config.h];  % [width, height] in mm
end

if nargout >= 2
    varargout{2} = [config.w_pix, config.h_pix];  % [width, height] in pixels
end

if nargout >= 3
    varargout{3} = config;  % Full config struct
end

end